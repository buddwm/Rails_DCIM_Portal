class Admin::BmcHostsController < AdminController

  before_action :set_bmc_host, only: [:show, :update, :destroy]
  include Admin::Filters
  layout "admin_page"
  add_breadcrumb "Home", "/"
  add_breadcrumb "Admin", :admin_path
  add_breadcrumb "BMC Hosts", :admin_bmc_hosts_path

  def index
    @bmc_hosts = BmcHost.all

    pick_filters(:bmc_host, zone_filters, bmc_host_filters)
    
    respond_to do |format|
      format.html
      format.json { render json: @bmc_hosts }
    end

  end

  def show
    add_breadcrumb @bmc_host.ip_address, admin_bmc_host_path
    respond_to do |format|
      format.html
      format.json { render json: @bmc_host }
    end
  end

  def update
    @bmc_host.refresh!
  end

  def multi_refresh
    BmcHostsRefreshJob.perform_later(params[:selected_ids])
  end

  def destroy
  end

  def onboard_modal
    selected_hosts = ids_to_bmc_hosts(params[:selected_ids])
    green, yellow, red = validate_bmc_hosts_for_onboard(selected_hosts)
    respond_to do |format|
      format.html { render layout: false, locals: { hosts: selected_hosts, red: red, yellow: yellow, green: green } }
    end
  end

  def multi_onboard
    add_breadcrumb "Onboard Request".html_safe
    input = params[:onboard]
    unless input.is_a?(ActionController::Parameters) && input[:bmc_host_ids].is_a?(Array)
      ids = []
      #redirect_back fallback_location: {action: 'index'}
      #return
    else
      ids = input[:bmc_host_ids]
    end

    selected_hosts = ids_to_bmc_hosts(ids)
    green, yellow, red = validate_bmc_hosts_for_onboard(selected_hosts)

    onboard_requests = []
    green.each do |item|
      bmc_host = item[:bmc_host]
#      bmc_host.update(onboard_request: OnboardRequest.new(bmc_host: bmc_host)) unless params[:noop]
      onboard_requests << bmc_host.onboard_request
    end
    yellow.each do |item|
      bmc_host = item[:bmc_host]
      onboard_requests << bmc_host.onboard_request
    end

    onboard_requests.each do |onboard_request|
#      OnboardJob.perform_later(foreman_resource: YAML::dump(@foreman_resource), request: onboard_request) unless params[:noop]
    end

    locals = { hosts: selected_hosts, red: red, yellow: yellow, green: green }

    respond_to do |format|
      format.html { render locals: locals }
      format.json { render json: locals }
    end
  end

  private

  def set_bmc_host
    @bmc_host = BmcHost.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_back fallback_location: {action: 'index'}
  end

end
