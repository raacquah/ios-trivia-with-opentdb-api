//
//  TriviaQuestion.swift
//  Trivia
//
//  Created by Mari Batilando on 4/6/23.
//

import Foundation

struct TriviaResponse: Decodable {
    let results: [TriviaQuestion]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.results = (try? container.decode([TriviaQuestion].self, forKey: .results)) ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case results
    }
}

// The CodingKeys enum has been removed from this struct.
struct TriviaQuestion: Decodable {
    let category: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
    
    var allAnswers: [String] {
        return (incorrectAnswers + [correctAnswer]).shuffled()
    }
}
