require 'rails_helper'

RSpec.describe "Tasks API", type: :request do
  let(:genre) { create(:genre) }

  describe 'POST /tasks' do
    it 'priorityパラメータを指定してタスクを作成できること' do
      post '/tasks', params: {
        name: 'New Task',
        explanation: 'Task description',
        priority: 'high',
        genreId: genre.id,
        deadlineDate: Date.today.to_s
      }

      expect(response).to have_http_status(:success)
      created_task = Task.last
      expect(created_task.priority).to eq('high')
    end

    it 'レスポンスJSONに作成されたタスクのpriorityが含まれていること' do
      post '/tasks', params: {
        name: 'New Task',
        explanation: 'Task description',
        priority: 'low',
        genreId: genre.id,
        deadlineDate: Date.today.to_s
      }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      created_task = json_response.find { |task| task['name'] == 'New Task' }
      expect(created_task['priority']).to eq('low')
    end
  end

  describe 'POST /tasks/:id/duplicate' do
    let!(:original_task) do
      create(:task,
        name: 'Original Task',
        explanation: 'Original explanation',
        deadline_date: Date.new(2025, 12, 31),
        status: :in_progress,
        priority: 'high',
        genre: genre
      )
    end

    # カテゴリ6: 正常系レスポンス
    describe '正常系' do
      it 'ステータスコードが200であること' do
        post "/tasks/#{original_task.id}/duplicate"

        expect(response).to have_http_status(200)
      end

      it 'レスポンスがJSON形式であること' do
        post "/tasks/#{original_task.id}/duplicate"

        expect(response.content_type).to match(/application\/json/)
      end

      it 'レスポンスに全タスクの配列が含まれること' do
        post "/tasks/#{original_task.id}/duplicate"

        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to be >= 2 # 元のタスク + 複製されたタスク
      end

      it 'タスクの総数が1増加すること' do
        expect {
          post "/tasks/#{original_task.id}/duplicate"
        }.to change(Task, :count).by(1)
      end

      it '複製されたタスクのnameに「(コピー)」が追加されていること' do
        post "/tasks/#{original_task.id}/duplicate"

        json_response = JSON.parse(response.body)
        duplicated_task = json_response.find { |task| task['name'] == 'Original Task(コピー)' }
        expect(duplicated_task).to be_present
      end

      it '複製されたタスクのstatusが0にリセットされていること' do
        post "/tasks/#{original_task.id}/duplicate"

        json_response = JSON.parse(response.body)
        duplicated_task = json_response.find { |task| task['name'] == 'Original Task(コピー)' }
        expect(duplicated_task['status']).to eq('not_started')
      end

      it '複製されたタスクのdeadlineDateがnullになっていること' do
        post "/tasks/#{original_task.id}/duplicate"

        json_response = JSON.parse(response.body)
        duplicated_task = json_response.find { |task| task['name'] == 'Original Task(コピー)' }
        expect(duplicated_task['deadlineDate']).to be_nil
      end
    end

    # カテゴリ8: エラーケース
    describe 'エラーケース' do
      it '存在しないIDを指定した場合、404が返ること' do
        post '/tasks/99999/duplicate'

        expect(response).to have_http_status(404)
      end

      it '無効なIDフォーマット（文字列）の場合、404が返ること' do
        post '/tasks/invalid_id/duplicate'

        expect(response).to have_http_status(404)
      end

      it 'IDパラメータが欠けている場合、404が返ること' do
        post '/tasks//duplicate'

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET /tasks/stats' do
    context 'タスクが存在しない場合' do
      it 'ステータスコードが200であること' do
        get '/tasks/stats'
        expect(response).to have_http_status(200)
      end

      it '全タスク数が0であること' do
        get '/tasks/stats'
        json_response = JSON.parse(response.body)
        expect(json_response['totalCount']).to eq(0)
      end

      it '完了率が0.0であること' do
        get '/tasks/stats'
        json_response = JSON.parse(response.body)
        expect(json_response['completionRate']).to eq(0.0)
      end

      it 'ステータス別タスク数が全て0であること' do
        get '/tasks/stats'
        json_response = JSON.parse(response.body)
        expect(json_response['statusCounts']['notStarted']).to eq(0)
        expect(json_response['statusCounts']['inProgress']).to eq(0)
        expect(json_response['statusCounts']['completed']).to eq(0)
      end
    end

    context 'タスクが存在する場合' do
      let!(:task1) { create(:task, status: :not_started, genre: genre) }
      let!(:task2) { create(:task, status: :in_progress, genre: genre) }
      let!(:task3) { create(:task, status: :completed, genre: genre) }
      let!(:task4) { create(:task, status: :completed, genre: genre) }

      it 'ステータスコードが200であること' do
        get '/tasks/stats'
        expect(response).to have_http_status(200)
      end

      it 'レスポンスがJSON形式であること' do
        get '/tasks/stats'
        expect(response.content_type).to match(/application\/json/)
      end

      it '全タスク数が正しいこと' do
        get '/tasks/stats'
        json_response = JSON.parse(response.body)
        expect(json_response['totalCount']).to eq(4)
      end

      it 'ステータス別タスク数が正しいこと' do
        get '/tasks/stats'
        json_response = JSON.parse(response.body)
        expect(json_response['statusCounts']['notStarted']).to eq(1)
        expect(json_response['statusCounts']['inProgress']).to eq(1)
        expect(json_response['statusCounts']['completed']).to eq(2)
      end

      it '完了率が正しく計算されること' do
        get '/tasks/stats'
        json_response = JSON.parse(response.body)
        expect(json_response['completionRate']).to eq(50.0)
      end
    end
  end

  describe 'GET /tasks/report' do
    context 'タスクが存在しない場合' do
      it 'ステータスコードが200であること' do
        get '/tasks/report'
        expect(response).to have_http_status(200)
      end

      it '全タスク数が0であること' do
        get '/tasks/report'
        json_response = JSON.parse(response.body)
        expect(json_response['totalCount']).to eq(0)
      end

      it '完了率が0.0であること' do
        get '/tasks/report'
        json_response = JSON.parse(response.body)
        expect(json_response['completionRate']).to eq(0.0)
      end

      it 'countByStatusキーが存在すること' do
        get '/tasks/report'
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('countByStatus')
      end

      it 'ステータス別タスク数が全て0であること' do
        get '/tasks/report'
        json_response = JSON.parse(response.body)
        expect(json_response['countByStatus']['notStarted']).to eq(0)
        expect(json_response['countByStatus']['inProgress']).to eq(0)
        expect(json_response['countByStatus']['completed']).to eq(0)
      end
    end

    context 'タスクが存在する場合' do
      let!(:task1) { create(:task, status: :not_started, genre: genre) }
      let!(:task2) { create(:task, status: :in_progress, genre: genre) }
      let!(:task3) { create(:task, status: :completed, genre: genre) }

      it 'ステータスコードが200であること' do
        get '/tasks/report'
        expect(response).to have_http_status(200)
      end

      it 'レスポンスがJSON形式であること' do
        get '/tasks/report'
        expect(response.content_type).to match(/application\/json/)
      end

      it '全タスク数が正しいこと' do
        get '/tasks/report'
        json_response = JSON.parse(response.body)
        expect(json_response['totalCount']).to eq(3)
      end

      it 'countByStatusキーが存在すること' do
        get '/tasks/report'
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('countByStatus')
      end

      it 'ステータス別タスク数が正しいこと' do
        get '/tasks/report'
        json_response = JSON.parse(response.body)
        expect(json_response['countByStatus']['notStarted']).to eq(1)
        expect(json_response['countByStatus']['inProgress']).to eq(1)
        expect(json_response['countByStatus']['completed']).to eq(1)
      end

      it '完了率が小数点1桁で計算されること' do
        get '/tasks/report'
        json_response = JSON.parse(response.body)
        expect(json_response['completionRate']).to eq(33.3)
      end
    end
  end
end
