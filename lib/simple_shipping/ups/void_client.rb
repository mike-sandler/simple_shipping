module SimpleShipping::Ups
  # Required credentials:
  # * _username_
  # * _password_
  # * _access_license_number_
  #
  # = Usage
  #  client = SimpleShipping::Ups::VoidClient.new(:username              => "USER NAME",
  #                                               :password              => "PASSWORD",
  #                                               :access_license_number => "LICENSE NUMBER")
  #  client.request(shipper, recipient, package) # => #<SimpleShipping::Ups::Response ...>
  class VoidClient < Client
    set_required_credentials :username, :password, :access_license_number

    set_wsdl_document       File.join(SimpleShipping::WSDL_DIR, "ups/Void.wsdl")
    set_production_address  "https://onlinetools.ups.com/webservices/Void"
    set_testing_address     "https://wwwcie.ups.com/webservices/Void"

    # Build VoidRequest and perform the request.
    #
    # @param shipment_identification_number [String]
    # @param options [Hash]
    def void_request(shipment_identification_number, options = {})
      request = VoidRequest.new(@credentials, shipment_identification_number, options)
      execute(request)
    end

    # @param [Hash] options Savon client options
    def client_options(options = {})
      super.deep_merge(
        :namespaces => {
          # Savon parses have WSDL instead of XMLSchema which is not accepted by UPS
          # So we have to again set namespace explicitly :( -- aignatev 20130204
          'xmlns:void' => "http://www.ups.com/XMLSchema/XOLTWS/Void/v1.1"
        }
      )
    end
    protected :client_options

    # Perform ShipmentRequest to UPS service.
    def execute(request)
      savon_response = @client.call(request.type, :message => request.body)
      log_response(savon_response)
      request.response(savon_response)
    rescue Savon::SOAPFault => err
      raise SimpleShipping::RequestError.new(err)
    end
    private :execute
  end
end
