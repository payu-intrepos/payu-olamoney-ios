![N|Solid](https://www.payubiz.in/images/logo.png)

# PayU Mobile SDK - Ola Money (iOS)

PayU's Ola Money SDK is framework for integrating Ola Money Postpaid + Wallet in your app in an easy, efficient and stable way. 


##### Ola Money SDK Frameworks
PayU provides SDK that perform different functions related to Ola Money Payments

__PayUOlaMoneySDK__: This contains all APIs, Error Codes, Request builder etc. With this SDK alone, you can create postData for Ola Money. 

##### Required Dependencies (Automatically added via Cocoapods)
1. __PayU Networking__: This is used by PayUOlaMoneySDK to handle network requests. 
2. __PayU Logger__: This is used by PayUOlaMoneySDK to log errors and verbose data. 


### Integration
##### Cocapods integration: 

Add following line in to your Podfile
```
pod 'PayUIndia-OlaMoney'
```

##### Manual integration
1. Download the framework files from here. https://github.com/payu-intrepos/payu-olamoney-ios/releases
2. Link to your project.


##### Make UPI Payments
1. Set environment to test or production 
    ```
    PayUOMCore.shared.environment = .production
    ```
3. Set Logger level to verbose, error or disabled

    ```
    PayUOMCore.shared.logLevel = .verbose
    ```

3. Set mandatory payment parameters required for the payment
    ```
    do {
            paymentParams = try PayUOMPaymentParams(
                merchantKey: "smsplus", //Your merchant key for the environment set in step 1
                transactionId: String.randomString(length: 10), //Your unique ID for this trasaction
                amount: "1", //Amount of transaction
                productInfo: "iPhone", // Description of the product
                firstName: "Ashish", lastName: "Jain", // First name of the user
                email: "johnappleseed@payu.in",// Email of the useer
                phoneNumber: phoneNumberTextField.text ?? "9717063173", // Phone of user
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
            //Helper.showAlert("Could not create post params due to: \(error.localizedDescription)", onController: self)
        }
    ```

4. Fetch hashes and save them in `paymentParams` object
    - You need to set `hashes` property in `paymentParams`. Hashes authenticates that API request originates from the original source and not from any Man in the middle. Property `hashes` is of type `PayUOMHashes`
    - `PayUHashes` has 2 properties. Each of these 3 is used for a distinct API call. These 3 properties are defined below:
        1. `paymentHash`: This is required to create transaction at PayU's end.
        3. `eligibilityHash`: This is required by checkEligibility API to check eligibility if use is eligible/registered for the Ola Money
    - You need to provide hashes before asking SDK to initiate the payment and check eligiblity. Hashes must be generated only on your server as it needs a secret key (also known as salt). Your app must never contain salt.
    - Please see [this documentation](https://raw.githubusercontent.com/payu-intrepos/Documentations/b69a85d7144056af4480563c1c013b5f3b94d755/Integration-Document-Version-2.11.pdf) to generate hashes on your server. 
        - See page 10 & 11 for formula of generating `paymentHash`. 
        - See page 36 for formula of generating `paymentRelatedDetailsForMobileSDKHash` & `validateVPAHash`

    - _Command_ and _var1_ values for generating `paymentRelatedDetailsForMobileSDKHash` & `validateVPAHash` are given below
    
        | Hash for param | Command | var1 |
        | ------ | ------ | ------- |
        | `eligibilityHash` | get_eligible_payment_options | {\"amount\":\"1\",\"txnid\":\""+txid+"\",\"mobile_number\":\"12345678\",\"first_name\":\"John\",\"bankCode\":\"OLAM\",\"email\":\"john.smith@gmail.com\",\"last_name\":\"Smith\"}|

5. After setting value of hashes in `paymentParams`, call following method of class `PayUOMCore` to check weacher user is eligible to pay through Ola Money (Postpaid + Wallet) :
    ```
    public func checkEligibility(params: PayUOMPaymentParams, completion:@escaping(_ status: Bool, _ response: PayUOMEligibilityModel?, _ error: Error?) -> Void)
    ```
    You will get a response of type `Result` with the value of type `PayUOMEligibilityModel` in response's success param. 
    Sample code shown below
    ```
    PayUOMCore.shared.checkEligibility(params: self.paymentParams!, completion: { [unowned self] status, response, error in
                DispatchQueue.main.async {
                    self.makePaymentButton.isEnabled = status
                    if (error != nil) {
                        self.elegebilityLabel.text = error?.localizedDescription
                    } else {
                        self.elegebilityLabel.text = response?.msg
                    }
                }
            })
    ```
6. With the `PayUOMEligibilityModel` object received above, you can populate relevant options on your checkout screen.

7. After checking the eligibilty, we can fetch the post params with the method. And can use the Custom Browser or WKWebView to load the URL and PostData
    ```
    public func getPostData(params: PayUOMPaymentParams) -> String 
    ```
8. (Optional) Use the custom browser to load data using following code.

    ```
    let customBrowser = try? PUCBWebVC(postParam: postData, url: PayUOMSecureEndPoint.securePayment.baseURL, merchantKey: "smsplus")
    customBrowser?.cbWebVCDelegate = self
    let navVC = UINavigationController(rootViewController: customBrowser!)
    self.present(navVC, animated: true, completion: nil)
    ```





