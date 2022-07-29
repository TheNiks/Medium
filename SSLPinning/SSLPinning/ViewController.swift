//
//  ViewController.swift
//  SSLPinning
//
//  Created by Nikunj Modi on 29/07/22.
//

import UIKit

struct User: Decodable {
        var userId: Int
        var id: Int
        var title: String?
}

class ViewController: UIViewController {
    private var session: URLSession?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //session = URLSession.shared
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        getHomeData()
    }
    
    func getHomeData() {
        session?.dataTask(with: URL(string: "https://run.mocky.io/v3/33d6bd59-d9f4-45a7-bbaf-c6f04aa47101")!, completionHandler: { data, response, error in
            
            if error == nil {
                do {
                    let dummyResponse = try JSONDecoder().decode(User.self, from: data!)
                    print(dummyResponse)
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Success", message: "We are getting proper User:\(dummyResponse.userId)", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                } catch {
                    print(error.localizedDescription)
                    let alert = UIAlertController(title: "Failure", message: "We are not getting proper response:\(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                
            }
        }).resume()
    }
}

extension ViewController: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                completionHandler(.cancelAuthenticationChallenge, nil);
                return
            }

            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)

            // SSL Policies for domain name check
            let policy = NSMutableArray()
            policy.add(SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString))

            //evaluate server certificate
            let isServerTrusted = SecTrustEvaluateWithError(serverTrust, nil)

            //Local and RemoteisServerTrusted    Bool    false     certificate Data
            let remoteCertificateData:NSData =  SecCertificateCopyData(certificate!)

            let pathToCertificate = Bundle.main.path(forResource: "mocky", ofType: "cer")
            //let pathToCertificate = Bundle.main.path(forResource: "apple", ofType: "cer")
            let localCertificateData:NSData = NSData(contentsOfFile: pathToCertificate!)!
            //Compare certificates
            if(isServerTrusted && remoteCertificateData.isEqual(to: localCertificateData as Data)){
                let credential:URLCredential =  URLCredential(trust:serverTrust)
                print("Certificate pinning is successfully completed")
                completionHandler(.useCredential,nil)
            }
            else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Failure", message:"Pinning failed" , preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                print("Certificate pinning is failed")
                completionHandler(.cancelAuthenticationChallenge,nil)
            }
        }
}
