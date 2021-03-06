module SimpleShipping::Ups
  # Required credentials:
  # * _username_
  # * _password_
  # * _access_license_number_
  #
  # = Usage
  #  client = SimpleShipping::Ups::ShipClient.new(:username              => "USER NAME",
  #                                             :password              => "PASSWORD",
  #                                             :access_license_number => "LICENSE NUMBER")
  #  client.request(shipper, recipient, package) # => #<SimpleShipping::Ups::Response ...>
  class ShipClient < Client
    set_required_credentials :username, :password, :access_license_number

    set_wsdl_document       File.join(SimpleShipping::WSDL_DIR, "ups/Ship.wsdl")
    set_production_address  "https://onlinetools.ups.com/webservices/Ship"
    set_testing_address     "https://wwwcie.ups.com/webservices/Ship"

    # @param shipper   [::SimpleShipping::Party]
    # @param recipient [::SimpleShipping::Party]
    # @param package   [::SimpleShipping::Package]
    # @param options   [Hash] ({})
    #
    # @return [::SimpleShipping::ShipmentResponse]
    #
    # @raise [::SimpleShipping::RequestError] in case of SOAP errors
    def shipment_request(shipper, recipient, package, options = {})
      shipment = create_shipment(shipper, recipient, package, options)
      request  = ShipmentRequest.new(@credentials, shipment, options)
      execute(request)
    end

    # Send shipment confirmation request.
    def ship_confirm_request(shipper, recipient, package, options = {})
      shipment = create_shipment(shipper, recipient, package, options)
      request  = ShipConfirmRequest.new(@credentials, shipment, options)
      execute(request)
    end


    # Perform shipping accept request.
    def ship_accept_request(shipment_digest, options = {})
      request  = ShipAcceptRequest.new(@credentials, shipment_digest, options)
      execute(request)
    end

    # @param [Hash] options Savon client options
    def client_options(options = {})
      super.deep_merge(
        :namespaces => {
          # Savon parses have WSDL instead of XMLSchema which is not accepted by UPS
          # So we have to again set namespace explicitly :( -- aignatev 20130204
          'xmlns:ship' => "http://www.ups.com/XMLSchema/XOLTWS/Ship/v1.0"
        }
      )
    end
    protected :client_options


    # Perform ShipmentRequest to UPS service.
    def execute(request)
      savon_response = @client.call(request.type, :message => request.body)
      log_response(savon_response)
      request.response(savon_response)
    rescue Savon::SOAPFault => e
      raise SimpleShipping::RequestError.new(e)
    end
    private :execute
  end
end
