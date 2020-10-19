//
//  APIManager.swift
//  OlaMoneySampleApp
//
//  Created by Ashish Jain on 24/01/20.
//  Copyright © 2020 PayU. All rights reserved.
//

import Foundation
import PayUOlaMoneySDK
import PayUNetworkingKit

enum SampleAppError: Error {
    static let internetUnavailable = "Please check you internet connection"
    static let jsonDecoding = "Response is not in JSON format"
    static let hashError = "Hashes could not be generated"

    case error(_ message: String)

    var description: String {
        switch self {
        case .error(let message):
            return message
        }
    }
}

struct APIManager {

    func getHashes(params: PayUOMPaymentParams, completion: @escaping(_ hashes: Hashes?, _ error: SampleAppError?) ->()) {
        let router = PayURouter<HashAPI>()
        router.request(.generateHash(params: params)) { (data, error) in
            guard let data = data, error == nil else {
                completion(nil, .error(SampleAppError.internetUnavailable))
                return
            }

            do {
                let apiResponse = try JSONDecoder().decode(Hashes.self, from: data)
                if apiResponse.status == 0 { //Success case
                    completion(apiResponse, nil)
                } else {
                    completion(nil, .error(apiResponse.message ?? ""))
                }

            } catch let err {
                print(err)
                completion(nil, .error(SampleAppError.jsonDecoding))
            }
        }
    }
}

enum HashAPI {
    case generateHash(params: PayUOMPaymentParams)
}

extension HashAPI: PayUEndPointType {
    var baseURL: URL {
        guard let url = URL(string: "https://payu.herokuapp.com/") else { fatalError("baseURL could not be configured.")}
        return url
    }

    var path: String {
        switch self {
        case .generateHash:
            return "get_hash"
        }
    }

    var httpMethod: PayUHTTPMethod {
        return .post
    }

    var task: PayUHTTPTask {
        switch self {
        case .generateHash(let params):
            return .requestParameters(bodyParameters: nil,
                                      urlParameters: ["key": params.merchantKey,
                                                      "txnid": params.transactionId,
                                                      "amount": params.amount,
                                                      "productinfo": params.productInfo,
                                                      "firstname": params.firstName,
                                                      "email": params.email,
                                                      "udf1": params.udf1,
                                                      "udf2": params.udf2,
                                                      "udf3": params.udf3,
                                                      "udf4": params.udf4,
                                                      "udf5": params.udf5,
                                                      "user_credentials": params.userCredentials ?? ""])
        }
    }

    var destination: PayUEncodingDestination? {
        return .queryString
    }
}

public struct Hashes: Codable {
    public let paymentOptionsHash, paymentHash, validateVPAHash: String?
    public let status: Int?
    public let message: String?

    public enum CodingKeys: String, CodingKey {
        case paymentOptionsHash = "payment_related_details_for_mobile_sdk_hash"
        case paymentHash = "payment_hash"
        case validateVPAHash = "validate_vpa_hash"
        case status, message
    }
}
