class ShowsController < ApplicationController

  def show
    Counter.create :id => Counter.count
    render :text => "counter : #{Counter.count}"
  end

end
