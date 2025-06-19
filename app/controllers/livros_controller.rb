class LivrosController < ApplicationController
  before_action :set_livro, only: %i[ show update destroy ]

  # GET /livros
  def index
    @livros = Livro.all

    render json: @livros
  end

  # GET /livros/1
  def show
    render json: @livro
  end

  # POST /livros
  def create
    @livro = Livro.new(livro_params)

    if @livro.save
      render json: @livro, status: :created, location: @livro
    else
      render json: @livro.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /livros/1
  def update
    if @livro.update(livro_params)
      render json: @livro
    else
      render json: @livro.errors, status: :unprocessable_entity
    end
  end

  # DELETE /livros/1
  def destroy
    @livro.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_livro
      @livro = Livro.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def livro_params
      params.require(:livro).permit(:name, :isbn, :description, :author)
    end
end
