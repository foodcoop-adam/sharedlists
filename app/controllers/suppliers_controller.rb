class SuppliersController < ApplicationController

  before_filter :authenticate_supplier_admin!, :except => [:index, :map, :new, :create]

  # GET /suppliers
  # GET /suppliers.xml
  def index
    @suppliers = suppliers_filter(params).all

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @suppliers.to_xml }
    end
  end

  # GET /suppliers/map
  def map
    @suppliers = suppliers_filter(params).all
    @markers = Gmaps4rails.build_markers(@suppliers) do |supplier, marker|
      marker.lat supplier.latitude
      marker.lng supplier.longitude
      picture = "type-#{supplier.stype}-16.png"
      picture = "type-other-16.png" unless File.exist?("app/assets/images/#{picture}")
      marker.picture url: view_context.image_path(picture), width: 16, height: 16
      marker.infowindow render_to_string(:partial => 'map_window', :locals => { :supplier => supplier })
    end
  end

  # GET /suppliers/1
  # GET /suppliers/1.xml
  def show
    @supplier = Supplier.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @supplier.to_xml }
    end
  end

  # GET /suppliers/new
  def new
    @supplier = Supplier.new
  end

  # GET /suppliers/1;edit
  def edit
    @supplier = Supplier.find(params[:id])
  end

  # POST /suppliers
  # POST /suppliers.xml
  def create
    @supplier = Supplier.new(params[:supplier])

    respond_to do |format|
      if @supplier.save
        flash[:notice] = 'Supplier was successfully created.'
        format.html { redirect_to supplier_url(@supplier) }
        format.xml  { head :created, :location => supplier_url(@supplier) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @supplier.errors.to_xml }
      end
    end
  end

  # PUT /suppliers/1
  # PUT /suppliers/1.xml
  def update
    @supplier = Supplier.find(params[:id])

    respond_to do |format|
      if @supplier.update_attributes(params[:supplier])
        flash[:notice] = 'Supplier was successfully updated.'
        format.html { redirect_to supplier_url(@supplier) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @supplier.errors.to_xml }
      end
    end
  end

  # DELETE /suppliers/1
  # DELETE /suppliers/1.xml
  def destroy
    @supplier = Supplier.find(params[:id])
    @supplier.destroy

    respond_to do |format|
      format.html { redirect_to suppliers_url }
      format.xml  { head :ok }
    end
  end


  protected

  def suppliers_filter(params)
    suppliers = Supplier
    suppliers = suppliers.where('name LIKE ?', "%#{params[:name]}%") unless params[:name].blank?
    suppliers = suppliers.where('stype = ?', params[:type]) unless params[:type].nil? or params[:type]=='(all)'
    suppliers = suppliers.joins(:articles).group('articles.supplier_id') if params[:with_articles]=='1'
    suppliers
  end
end
