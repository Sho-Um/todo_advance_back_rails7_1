class TasksController < ApplicationController
  before_action :select_task, only: [:update, :destroy, :update_status, :duplicate]
  skip_before_action :verify_authenticity_token

  def index
    tasks_all
  end

  def create
    TaskService.create(params)
    tasks_all
  end

  def update
    @task.update(task_params)
    tasks_all
  end

  def destroy
    @task.destroy
    tasks_all
  end

  def update_status
    @task.update(status: params[:status])
    tasks_all
  end

  def duplicate
    Tasks::DuplicateService.call(@task)
    tasks_all
  end

  def stats
    @stats = Task.stats
    render :stats
  end

  def report
    stats = Task.stats
    render json: {
      totalCount: stats[:total_count],
      countByStatus: {
        notStarted: stats[:status_counts][:not_started],
        inProgress: stats[:status_counts][:in_progress],
        completed: stats[:status_counts][:completed]
      },
      completionRate: stats[:completion_rate].round(1)
    }
  end

  private

  def task_params
    params.permit(:name, :explanation, :status, :priority).merge(genre_id: params[:genreId], deadline_date: params[:deadlineDate])
  end

  def select_task
    @task = Task.find(params[:id])
  end

  def tasks_all
    @tasks = Task.includes(:genre).all
    render :all_tasks
  end
end
