module SuppliersHelper
  def ofn_enterprise_path(id)
    "#{Source::OFN.base_uri}/producers/#{id}"
  end
end
