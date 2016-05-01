class TagsController < ApplicationController

  before_action :set_tag, only: [:show, :edit, :update, :destroy, :advice]
  http_basic_authenticate_with name: "admin", password: Rails.configuration.x.admin_password, except: [:index,:advice] unless Rails.env.test?

  # GET /tags
  # GET /tags.json
  def index
    @tags = Tag.all
  end

  # GET /tags/1
  # GET /tags/1.json
  def show
  end

  # GET /tags/new
  def new
    @tag = Tag.new
  end

  # GET /tags/1/edit
  def edit
  end

  # POST /tags
  # POST /tags.json
  def create
    @tag = Tag.new(tag_params)

    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: 'Tag was successfully created.' }
        format.json { render :show, status: :created, location: @tag }
      else
        format.html { render :new }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tags/1
  # PATCH/PUT /tags/1.json
  def update
    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to @tag, notice: 'Tag was successfully updated.' }
        format.json { render :show, status: :ok, location: @tag }
      else
        format.html { render :edit }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.json
  def destroy
    @tag.destroy
    respond_to do |format|
      format.html { redirect_to tags_url, notice: 'Tag was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def advice
    # First, let's sync up the stacks for this tag
    Stack.sync_from_stackshare_api @tag.api_id
    # Is there a most popular stack
    @most_popular_stack = Stack.joins(:tags).order(popularity: :desc).where("tags.id = ?", @tag.id).limit(1).first
    # If there is one, fetching / parsing some more needed data
    if @most_popular_stack.present?
      @company = JSON.parse @most_popular_stack.full_object['company'].gsub('=>',':')
      @tags = JSON.parse @most_popular_stack.full_object['tags'].gsub('=>',':')
      @tools_by_layer_id = @most_popular_stack.tools.group_by(&:layer_id)
      @all_layers = Layer.order :api_id
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tag
      @tag = Tag.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tag_params
      params.require(:tag).permit(:name, :api_id)
    end
end
