require 'dotenv'
Dotenv.load

require 'sinatra/base'
require 'active_support/all'
require 'better_errors'
require 'stellar-base'
require 'memoist'

require_relative "./db"

class App < Sinatra::Base
  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = __dir__
  end

  configure{ set :method_override, true }

  # UI Routes
  get "/" do
    redirect "/client"
  end

  get "/client" do
    haml :new, layout: :application
  end

  get "/client/:hash" do
    tx = Transaction.where(hash_hex:params[:hash]).first
    raise "couldn't find tx" if tx.blank?

    haml :show, layout: :application, locals:{
      tx: tx
    }

  end


  # API Routes

  post '/transactions' do
    hex = params['hex']
    raw = Stellar::Convert.from_hex(hex)
    tx = Stellar::Transaction.from_xdr raw

    txm = Transaction.create!({
      hash_hex: Stellar::Convert.to_hex(tx.hash),
      tx_hex: hex,
    })

    redirect "/client/#{txm.hash_hex}"
  end

  patch '/transactions/:hash' do
    txm = Transaction.where(hash_hex:params[:hash]).first
    raise "couldn't find tx" if txm.blank?

    if params[:seed].present?
      txm.add_signature!(params[:seed])
    end

    # TODO: add any provided verifications

    redirect "/client/#{txm.hash_hex}"
  end


  # helpers
  helpers do
    def truncate(input, max=30)
      return input if input.length <= max

      input[0...max] + "..."
    end
  end
end
