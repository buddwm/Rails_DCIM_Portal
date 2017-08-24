class BmcHostDatatable < ApplicationDatatable

  def_delegator :@view, :link_to
  def_delegator :@view, :radio_button_tag

  def view_columns
    @view_columns ||= {
      ip_address: {source: "BmcHost.ip_address", orderable: true},
      system_model: {source: "BmcHost.system_model"},
      serial: {source: "BmcHost.serial"},
      zone_name: {source: "Zone.name"},
      power_status: {source: "BmcHost.power_status", searchable: false, orderable: true},
      sync_status: {source: "BmcHost.sync_status", searchable: false, orderable: true},
      onboard_request_status: {source: "OnboardRequest.status", searchable: false, orderable: true},
      onboard_request_step: {source: "OnboardRequest.step", searchable: false, orderable: false},
      updated_at: {source: "BmcHost.updated_at", searchable: false, orderable: true}
    }
  end

  def data
    records.map do |record| {
      ip_address: record.ip_address,
      system_model: record.system_model,
      serial: record.serial,
      zone_name: record.zone.name,
      power_status: record.power_status,
      sync_status: record.sync_status,
      onboard_request_status: record.onboard_request.try(:status),
      onboard_request_step: record.onboard_request.try(:step),
      updated_at: record.updated_at.to_time.iso8601,
      checkbox: radio_button_tag('record', record.id),
      url: link_to('Details', record, class: "btn blue lighten-2"),
      zone_id: record.zone.id,
      onboard_request_id: record.onboard_request.try(:id),
      'DT_RowId' => record.id
    }
    end
  end

  private

  def get_raw_records
    query = BmcHost.includes(:onboard_request, :zone).references(:onboard_request, :zone).all
    params_bmc_host = params[:bmc_host] || {}
    params_onboard_request = params[:onboard_request] || {}
    params_bmc_host.each do |key, value|
      query = query.where({key.to_sym => value}) if value.present?
    end
    params_onboard_request.each do |key, value|
      query = query.joins(:onboard_request).merge(OnboardRequest.where({key.to_sym => value})) if value.present?
    end
    query
  end


  # ==== These methods represent the basic operations to perform on records
  # and feel free to override them

  # def filter_records
  # end

  # def sort_records(records)
  # end

  # def paginate_records(records)
  # end

  # ==== Insert 'presenter'-like methods below if necessary
end