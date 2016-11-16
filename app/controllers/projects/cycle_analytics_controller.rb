class Projects::CycleAnalyticsController < Projects::ApplicationController
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper

  before_action :authorize_read_cycle_analytics!

  def show
    @cycle_analytics = CycleAnalytics.new(@project, from: parse_start_date)

    respond_to do |format|
      format.html
      format.json { render json: cycle_analytics_json }
    end
  end

  private

  def parse_start_date
    case cycle_analytics_params[:start_date]
    when '30' then 30.days.ago
    when '90' then 90.days.ago
    else 90.days.ago
    end
  end

  def cycle_analytics_params
    return {} unless params[:cycle_analytics].present?

    { start_date: params[:cycle_analytics][:start_date] }
  end

  def cycle_analytics_json
    cycle_analytics_view_data = [[:issue, "Issue", "Related Issues", "Time before an issue gets scheduled"],
                                 [:plan, "Plan", "Related Commits", "Time before an issue starts implementation"],
                                 [:code, "Code", "Related Merge Requests", "Time spent coding"],
                                 [:test, "Test", "Relative Builds Trigger by Commits", "The time taken to build and test the application"],
                                 [:review, "Review", "Relative Merged Requests", "The time taken to review the code"],
                                 [:staging, "Staging", "Relative Deployed Builds", "The time taken in staging"],
                                 [:production, "Production", "Related Issues", "The total time taken from idea to production"]]

    stats = cycle_analytics_view_data.reduce([]) do |stats, (stage_method, stage_text, stage_legend, stage_description)|
      value = @cycle_analytics.send(stage_method).presence

      stats << {
        title: stage_text,
        description: stage_description,
        legend: stage_legend,
        value: value && !value.zero? ? distance_of_time_in_words(value) : nil
      }
      stats
    end

    issues = @cycle_analytics.summary.new_issues
    commits = @cycle_analytics.summary.commits
    deploys = @cycle_analytics.summary.deploys

    summary = [
      { title: "New Issue".pluralize(issues), value: issues },
      { title: "Commit".pluralize(commits), value: commits },
      { title: "Deploy".pluralize(deploys), value: deploys }
    ]

    {
      summary: summary,
      stats: stats
    }
  end
end
