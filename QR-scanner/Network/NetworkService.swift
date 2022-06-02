//
//  NetworkService.swift
//  QR-scanner
//
//  Created by Ильяяя on 02.06.2022.
//

import Foundation

enum NetworkError : String {
    case ConnectionError = "Internet connection has been lost"
    case ServiceError = "Server answer is incorrect"
}

class NetworkService {
    
    private func url(date: Date, params : [String:String] = [:]) -> URL{
        var components = URLComponents()
        components.scheme = "https"
        components.host = "isdayoff.ru"
        
        let dateFormatterURL = DateFormatter()
        dateFormatterURL.dateFormat = "yyyyMMdd"
        let sUrlDate = dateFormatterURL.string(from: date)
        components.path = "/" + sUrlDate
        
        return components.url!
    }


    func fetchDate( date: Date, complition: @escaping (Int?, (String, Bool)?) -> Void){
        request(date: date) { (data, error) in
            if let _ = error {
                let errorString = NetworkError.ConnectionError.rawValue
                complition(nil, (errorString,true))
                return
            }
            if let data = data {
                if data.count == 0 {
                    complition(nil, (NetworkError.ServiceError.rawValue,true)); return
                }

                let sData = String.init(data: data, encoding: String.Encoding.utf8)
                let code = Int.init(sData ?? "")
                
                if code == nil {
                    complition(nil, (NetworkError.ServiceError.rawValue,true)); return
                }
                else if code != 0 && code != 1 {
                    complition(nil, (NetworkError.ServiceError.rawValue,true)); return
                }
                
                complition( code, nil )
            }
        }
    }
    
    private func request( date: Date, comp: @escaping (Data?,Error?) -> Void){
        let url = url(date: date)
        var request = URLRequest(url: url)
        request.httpMethod = "get"
        let task = createDataTask(from: request, comp: comp)
        task.resume()
        
    }
    
    private func createDataTask(from request:URLRequest, comp:@escaping (Data?, Error?) -> Void) -> URLSessionDataTask{
        return URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                comp(data,error)
            }
        }
    }
}
