class Build < ActiveRecord::Base
  belongs_to :project
  has_many :results, :autosave => true

  scope :recent_first, order('created_at DESC')

  before_create :create_default_results

  def last
    recent_first.limit(1)
  end

  def results_in_status(status)
    results.select {|r| r.in_status? status}.count
  end

  def short_hash
    commit_hash.try :[], 0..9
  end

  def status
    [:busy, :failed, :pending, :skipped].each do |status|
      return status unless results_in_status(status).zero?
    end
    :passed
  end

  def start_time
    results.first.start_time
  end

  def end_time
    results.last.end_time
  end

  def create_default_results
    project.commands.each do |command|
      results.build(:command => command)
    end
  end

  def has_commit_info?
    commit_hash.present? && commit_message.present? && commit_author.present? && commit_date.present?
  end

  # WORK

  def skip!
    results.each do |result|
      result.update_attribute :status_id, Result::STATUS[:skipped]
    end
  end

  def build!
    results.each do |result|
      result.update_attribute :status_id, 'busy'

      res = system("[[ -s \"$HOME/.rvm/scripts/rvm\" ]] && source \"$HOME/.rvm/scripts/rvm\"; cd #{project.folder_path}; #{result.command.command}")
      puts "[[ -s \"$HOME/.rvm/scripts/rvm\" ]] && source \"$HOME/.rvm/scripts/rvm\"; cd #{project.folder_path}; #{result.command.command}"
      if res
        result.update_attribute :status_id, 'passed'
      else
        result.update_attribute :status_id, 'failed'
      end
    end
  end

  def fetch_commit!
    git = Git.open(project.folder_path)
    git.fetch
    branch = git.branches["remotes/origin/#{project.branch}"] # TODO: make this smarter
    commit = branch.gcommit.log(1).first
    self.commit_hash = commit.sha
    self.commit_message = commit.message
    self.commit_author = commit.author.name
    self.commit_date = commit.date
    save!
  end
end
