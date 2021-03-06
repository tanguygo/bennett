module BuildsHelper
  def build_information(build)
    if build.has_commit_info?
      content_tag(:div, build.short_hash, :class => 'commit-hash') +
      content_tag(:div, build.commit_message, :class => 'commit-message') +
      content_tag(:div, author_and_date(build), :class => 'commit-details') +
      content_tag(:div, build_time(build), :class => 'commit-time')
    else
      content_tag(:div, 'Waiting for commit info...', :class => 'commit-waiting')
    end
  end

  def build_results_in_tds(build)
    build.results.collect do |result|
      content_tag :td, :class => "result-cell" do
        content_tag :span, [:busy, :passed, :failed].include?(result.status) ? link_to(status_image(result.status), [build.project, build, result]) : status_image(result.status) , :class => "status"
      end
    end.join.html_safe
  end

  def author_and_date(build)
    (content_tag(:span, build.commit_date, :class => 'commit-date') +
     ' by ' + content_tag(:span, build.commit_author, :class => 'commit-author')).html_safe
  end

  def build_time(build)
    start_time = build.start_time.to_s || ""
    end_time = build.end_time.to_s || ""
    content_tag(:span, ("Started at: " + start_time + " - Ended at: " + end_time ))
  end
  
  def status_image(status)
    format = case status
      when :busy then 'gif'
      else 'png'
    end
    image_tag "/assets/#{status}.#{format}", alt: status.to_s, title: status.to_s
  end
end
