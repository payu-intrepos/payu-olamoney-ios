//
//  ViewController.swift
//  OlaMoneySampleApp
//
//  Created by Ashish Jain on 20/01/20.
//  Copyright © 2020 PayU. All rights reserved.
//

import UIKit
import CommonCrypto
import PayUCustomBrowser
import PayUOlaMoneySDK

class ViewController: UIViewController {

    @IBOutlet weak var eligibilityLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var makePaymentButton: UIButton!
    var paymentParams: PayUOMPaymentParams?
    var presentedVC: UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        eligibilityLabel.text = ""
        phoneNumberTextField.delegate = self
        setupParams()
    }



    @IBAction func checkElgClicked(_ sender: Any) {
        phoneNumberTextField.resignFirstResponder()
        eligibilityLabel.text = ""
        makePaymentButton.isEnabled = false
        
        guard let paymentParams = paymentParams else {
            return
        }

        fetchHashes(withParams: paymentParams) { (result) in
            
            // This is for testing purpose, always calculate hash on your server side for better security
            let hashStr = "smsplus|get_eligible_payment_options|" + PayUOMCoreUtils.getJsonStringForElegibilityAPI(fromParams: paymentParams) + "|1b1b0"
            self.paymentParams?.hashes?.eligibilityHash = hashStr.sha512()

            PayUOMCore.shared.checkEligibility(params: paymentParams, completion: { [unowned self] status, response, error in
                DispatchQueue.main.async {
                    self.makePaymentButton.isEnabled = status
                    if (error != nil) {
                        self.eligibilityLabel.text = error?.localizedDescription
                    } else {
                        self.eligibilityLabel.text = response?.msg
                    }
                }
            })
        }

    }
    @IBAction func makePaymentClicked(_ sender: Any) {
        DispatchQueue.main.async {
            let postData = PayUOMCore.shared.getPostData(params: self.paymentParams!)
            let customBrowser = try? PUCBWebVC(postParam: postData, url: PayUOMSecureEndPoint.securePayment().baseURL, merchantKey: "smsplus")
            customBrowser?.cbWebVCDelegate = self
            let navVC = UINavigationController(rootViewController: customBrowser!)
            self.presentedVC = navVC
            self.present(navVC, animated: true, completion: nil)
        }
    }


    func setupParams() {
        PayUOMCore.shared.environment = .production
        PayUOMCore.shared.logLevel = .verbose
        do {
            paymentParams = try PayUOMPaymentParams(
                merchantKey: "smsplus", //Your merchant key for the environment set in step 1
                transactionId: String.randomString(length: 10), //Your unique ID for this trasaction
                amount: "1", //Amount of transaction
                productInfo: "iPhone", // Description of the product
                firstName: "Ashish", lastName: "Jain", // First name of the user
                email: "johnappleseed@payu.in",// Email of the useer
                phoneNumber: phoneNumberTextField.text ?? "9876543210", // Phone of user
                //User defined parameters.
                //You can save additional details with each txn if you need them for your business logic.
                //You will get these details back in payment response and transaction verify API
                //Like, you can add SKUs for which payment is made.
                udf1: "SKU1|SKU2|SKU3",
                //You can keep all udf fields blank if you do not have any requirement to save txn specific data
                udf2: "asdf",
                udf3: "asdf",
                udf4: "asdf",
                udf5: "asdf")

            // Example userCredentials - "merchantKey:user'sUniqueIdentifier"
            paymentParams?.userCredentials = "smsplus:myUserEmail@payu.in"
            // Success URL. Not used but required due to mandatory check.
            paymentParams?.surl = "https://payu.herokuapp.com/ios_success"
            // Failure URL. Not used but required due to mandatory check.
            paymentParams?.furl = "https://payu.herokuapp.com/ios_failure"
            paymentParams?.offerKey = "cardnumber@8370,cardnumbers2@8380,for particular bins@8427,srioffer@8428,cc2@8429"
        } catch let error {
            print(error.localizedDescription)
            return
        }
    }
    
    func fetchHashes(withParams params: PayUOMPaymentParams,
                     completion: @escaping(Result<Bool, SampleAppError> )->()) {
        
        guard let paymentParams = paymentParams else {
            return
        }
        
        APIManager().getHashes(params: paymentParams) {[weak self] (hashes, error) in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
            }
            
            if let hashes = hashes {
                print(hashes)
                self.paymentParams?.hashes = self.getPayUHashesModel(fromHashes: hashes)
                
                completion(.success(true))
                
            } else {
                completion(.failure(.error(SampleAppError.hashError)))
            }
        }
    }
    
    func getPayUHashesModel(fromHashes hashes: Hashes) -> PayUOMHashes{
        let payuHashes = PayUOMHashes()
        payuHashes.paymentHash = hashes.paymentHash
        
        return payuHashes
    }
    
    
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        paymentParams?.phoneNumber = textField.text ?? "9876543210"
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ViewController: PUCBWebVCDelegate {
    func payUSuccessResponse(_ response: Any!) {
        presentedVC?.dismiss(animated: true, completion: {
            self.showSimpleAlert(msg: response! as? String)
        })
    }
    
    func payUFailureResponse(_ response: Any!) {
        presentedVC?.dismiss(animated: true, completion: {
            self.showSimpleAlert(msg: response! as? String)
        })
    }
    
    func payUConnectionError(_ notification: [AnyHashable : Any]!) {
        presentedVC?.dismiss(animated: true, completion: {
            self.showSimpleAlert(msg: "Connection Error")
        })
    }
    
    func payUTransactionCancel() {
        presentedVC?.dismiss(animated: true, completion: {
            self.showSimpleAlert(msg: "Transaction Canceled")
        })
    }
    
    func payUSuccessResponse(_ payUResponse: Any!, surlResponse: Any!) {
        //        showSimpleAlert(payUResponse! as? String)
    }
    
    func payUFailureResponse(_ payUResponse: Any!, furlResponse: Any!) {
        //        showSimpleAlert(payUResponse! as? String)
    }
    
    func showSimpleAlert(msg: String?) {
        let alert = UIAlertController(title: "Status", message: msg, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { _ in
            //Cancel Action
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension String {
    
    func sha512() -> String {
        let data = self.data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes({
            _ = CC_SHA512($0, CC_LONG(data.count), &digest)
        })
        return digest.map({ String(format: "%02hhx", $0) }).joined(separator: "")
    }

    static func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
}
