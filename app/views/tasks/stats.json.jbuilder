json.totalCount @stats[:total_count]
json.statusCounts do
  json.notStarted @stats[:status_counts][:not_started]
  json.inProgress @stats[:status_counts][:in_progress]
  json.completed @stats[:status_counts][:completed]
end
json.completionRate @stats[:completion_rate]
