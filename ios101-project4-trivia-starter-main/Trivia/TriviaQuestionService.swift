//
//  TriviaQuestionService.swift
//  Trivia
//
//  Created by
//

import Foundation

class TriviaQuestionService {
    
    // Defines a custom error type for networking issues.
    enum TriviaError: Error {
        case networkError(Error)
        case decodingError(Error)
        case invalidURL
        case noData
    }
    
    // A static function allows us to call it without creating an instance of the class.
    static func fetchTrivia(categoryID: Int? = nil, difficulty: String? = nil, completion: @escaping ([TriviaQuestion]?, TriviaError?) -> Void) {
        
        // Use URLComponents to build the URL safely
        var components = URLComponents(string: "https://opentdb.com/api.php")!
        
        // Base query items
        var queryItems = [URLQueryItem(name: "amount", value: "5"),
                          URLQueryItem(name: "type", value: "multiple")]
        
        // Add category if one was provided
        if let categoryID = categoryID {
            queryItems.append(URLQueryItem(name: "category", value: String(categoryID)))
        }
        
        // Add difficulty if one was provided
        if let difficulty = difficulty {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficulty))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            completion(nil, .invalidURL)
            return
        }
        
        // The rest of the network request logic remains the same...
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, .networkError(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, .noData)
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let triviaResponse = try decoder.decode(TriviaResponse.self, from: data)
                
                DispatchQueue.main.async {
                    completion(triviaResponse.results, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, .decodingError(error))
                }
            }
        }
        
        task.resume()
    }
}
























