class SyncMailer < ActionMailer::Base

  def sync_result(to, msg, error_count)
    @msg = msg
    @error_count = error_count
    subject = (error_count > 0) ? "Import error!" : "Import succeeded"
    mail(to: to, subject: "[sharedlists] #{subject}")
  end

end
