class Task < ApplicationRecord
  belongs_to :genre

  enum status: { not_started: 0, in_progress: 1, completed: 2 }
  enum priority: { low: 0, medium: 1, high: 2 }

  def self.stats
    total_count = count
    status_counts = group(:status).count
    completed_count = status_counts['completed'] || 0
    completion_rate = total_count.zero? ? 0.0 : (completed_count.to_f / total_count * 100).round(2)

    {
      total_count: total_count,
      status_counts: {
        not_started: status_counts['not_started'] || 0,
        in_progress: status_counts['in_progress'] || 0,
        completed: completed_count
      },
      completion_rate: completion_rate
    }
  end
end
