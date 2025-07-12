//
//  ViewController.swift
//  Trivia
//
//  Created by Mari Batilando on 4/6/23.
//

import UIKit

class TriviaViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var currentQuestionNumberLabel: UILabel!
    @IBOutlet weak var questionContainerView: UIView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var answerButton0: UIButton!
    @IBOutlet weak var answerButton1: UIButton!
    @IBOutlet weak var answerButton2: UIButton!
    @IBOutlet weak var answerButton3: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties
    private var questions = [TriviaQuestion]()
    private var currQuestionIndex = 0
    private var numCorrectQuestions = 0
    
    // Properties to store user's choices
    private var selectedCategoryID: Int?
    private var selectedDifficulty: String?
    
    private var answerButtons: [UIButton] {
        return [answerButton0, answerButton1, answerButton2, answerButton3]
    }
    
    // New properties for dynamic theming
        private let gradientLayer = CAGradientLayer()
        private let defaultGradient = [
            UIColor(red: 0.54, green: 0.88, blue: 0.99, alpha: 1.00).cgColor,
            UIColor(red: 0.51, green: 0.81, blue: 0.97, alpha: 1.00).cgColor
        ]
        private let difficultyGradients: [String: [CGColor]] = [
            "easy": [UIColor.systemGreen.cgColor, UIColor.systemTeal.cgColor],
            "medium": [UIColor.systemOrange.cgColor, UIColor.systemYellow.cgColor],
            "hard": [UIColor.systemRed.cgColor, UIColor.systemBrown.cgColor]
        ]
        private let categoryColors: [Int: UIColor] = [
            9: .systemBlue,      // General Knowledge
            11: .systemIndigo,   // Film
            12: .systemPurple,   // Music
            17: .systemTeal,     // Science & Nature
            18: .darkGray,       // Computers
            21: .systemOrange    // Sports
        ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Present the settings alert here, after the view is in the window hierarchy.
        presentCategorySelectionAlert()
    }
    
    // MARK: - Game Flow
    private func fetchTriviaQuestions() {
        // --- START: Add these new lines for theming ---
            
            // Set the background gradient based on difficulty
            let gradient = difficultyGradients[selectedDifficulty ?? ""] ?? defaultGradient
            updateGradient(colors: gradient)
            
            // Set the question box color based on category
            let color = categoryColors[selectedCategoryID ?? 0] ?? UIColor.white
            questionContainerView.backgroundColor = color
            
            // --- END: New lines for theming ---
        
        // Show loading state
        questionContainerView.isHidden = true
        activityIndicator.startAnimating()
        
        // Pass the selected options to the network service
        TriviaQuestionService.fetchTrivia(categoryID: selectedCategoryID, difficulty: selectedDifficulty) { [weak self] (fetchedQuestions, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()

                if let error = error {
                    self.showErrorAlert(for: error)
                    return
                }

                guard let fetchedQuestions = fetchedQuestions, !fetchedQuestions.isEmpty else {
                    self.showErrorAlert(message: "No questions found for your selection. Please try different options.")
                    return
                }

                self.questions = fetchedQuestions
                self.currQuestionIndex = 0
                self.numCorrectQuestions = 0
                self.updateQuestion(withQuestionIndex: 0)
                self.questionContainerView.isHidden = false
            }
        }
    }

    // MARK: - Answering Logic
    private func updateQuestion(withQuestionIndex questionIndex: Int) {
        guard questionIndex < self.questions.count else { return }
        
        // Reset button appearance for the new question
        answerButtons.forEach {
            $0.backgroundColor = .clear
            $0.isEnabled = true
            $0.alpha = 1.0 // <-- ADD THIS LINE to reset the transparency
        }
        
        let question = self.questions[questionIndex]
        
        currentQuestionNumberLabel.text = "Question: \(questionIndex + 1)/\(self.questions.count)"
        questionLabel.text = question.question.decodingHTMLEntities
        categoryLabel.text = question.category.decodingHTMLEntities
        
        let answers = question.allAnswers
        
        // Hide all buttons initially to handle questions with fewer than 4 answers
        answerButtons.forEach { $0.isHidden = true }
        
        // Configure the visible buttons with new answers
        for (index, answer) in answers.enumerated() {
            if index < self.answerButtons.count {
                let button = self.answerButtons[index]
                button.setTitle(answer.decodingHTMLEntities, for: .normal)
                button.isHidden = false
            }
        }
    }
    
    private func updateToNextQuestion(selectedButton: UIButton) {
        // Disable all buttons to prevent multiple taps
        answerButtons.forEach { $0.isEnabled = false }
        
        // Check if the selected answer was correct
        let selectedAnswer = selectedButton.titleLabel?.text ?? ""
        if isCorrectAnswer(selectedAnswer) {
            numCorrectQuestions += 1
        }

        // Provide instant feedback
        for button in answerButtons {
            let correctAnswer = questions[currQuestionIndex].correctAnswer.decodingHTMLEntities
            
            // Set background colors
            if button.titleLabel?.text == correctAnswer {
                button.backgroundColor = .systemGreen
            } else {
                button.backgroundColor = .systemRed
            }
            
            // Fade out the buttons that weren't selected
            if button != selectedButton {
                button.alpha = 0.5
            }
        }
        
        // Wait one second, then move to the next question
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currQuestionIndex += 1
            if self.currQuestionIndex < self.questions.count {
                self.updateQuestion(withQuestionIndex: self.currQuestionIndex)
            } else {
                self.showFinalScore()
            }
        }
    }
    
    private func isCorrectAnswer(_ answer: String) -> Bool {
        guard currQuestionIndex < questions.count else { return false }
        return answer == questions[currQuestionIndex].correctAnswer.decodingHTMLEntities
    }

    // MARK: - UI Configuration and Alerts
    private func presentCategorySelectionAlert() {
        let alert = UIAlertController(title: "Choose a Category", message: nil, preferredStyle: .actionSheet)
        
        // API Category IDs: General=9, Film=11, Music=12, Science=17, Computers=18
        let categories: [(name: String, id: Int?)] = [
            ("Any Category", nil),
            ("General Knowledge", 9),
            ("Film", 11),
            ("Music", 12),
            ("Science & Nature", 17),
            ("Computers", 18)
        ]
        
        for category in categories {
            alert.addAction(UIAlertAction(title: category.name, style: .default, handler: { _ in
                self.selectedCategoryID = category.id
                self.presentDifficultySelectionAlert()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func presentDifficultySelectionAlert() {
        let alert = UIAlertController(title: "Choose a Difficulty", message: nil, preferredStyle: .actionSheet)
        
        let difficulties: [(name: String, value: String?)] = [
            ("Any Difficulty", nil),
            ("Easy", "easy"),
            ("Medium", "medium"),
            ("Hard", "hard")
        ]
        
        for difficulty in difficulties {
            alert.addAction(UIAlertAction(title: difficulty.name, style: .default, handler: { _ in
                self.selectedDifficulty = difficulty.value
                self.fetchTriviaQuestions() // Start the game with chosen settings
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func showFinalScore() {
        let alertController = UIAlertController(title: "Game Over!",
                                              message: "Final score: \(numCorrectQuestions)/\(questions.count)",
                                              preferredStyle: .alert)

        // 1. Add a "Replay" action
        // This action resets the game state and shows the first question again,
        // using the same questions that were just played.
        let replayAction = UIAlertAction(title: "Replay", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.currQuestionIndex = 0
            self.numCorrectQuestions = 0
            self.updateQuestion(withQuestionIndex: 0)
        }

        // 2. The "New Game" action (previously "Play Again")
        // This action goes back to the settings menu to start a completely new game.
        let newGameAction = UIAlertAction(title: "New Game", style: .default) { [weak self] _ in
            self?.presentCategorySelectionAlert()
        }
        
        // 3. Add both actions to the alert
        alertController.addAction(replayAction)
        alertController.addAction(newGameAction)
        
        present(alertController, animated: true)
    }
    
    private func showErrorAlert(for error: Error? = nil, message: String? = nil) {
        var errorMessage = "An unknown error occurred."
        if let error = error {
            errorMessage = error.localizedDescription
        } else if let message = message {
            errorMessage = message
        }
        
        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        
        let tryAgainAction = UIAlertAction(title: "Try Again", style: .default) { [unowned self] _ in
            self.presentCategorySelectionAlert()
        }
        
        alertController.addAction(tryAgainAction)
        present(alertController, animated: true)
    }
    
    private func configureUI() {
        // Initial gradient setup
        gradientLayer.frame = view.bounds
        gradientLayer.colors = defaultGradient
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // --- START: New Font Configuration ---
        
        // Use a heavier weight for the main question
        questionLabel.font = UIFont(name: "Poppins-SemiBold", size: 30)
        
        // Use a medium weight for the category and question number
        categoryLabel.font = UIFont(name: "Poppins-Medium", size: 18)
        currentQuestionNumberLabel.font = UIFont(name: "Poppins-Medium", size: 18)
        
        // Use a regular weight for the answer buttons
        for button in answerButtons {
            button.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 20)
            button.layer.cornerRadius = 8.0
        }
        
        // --- END: New Font Configuration ---
        
        questionContainerView.layer.cornerRadius = 12.0
    }

    // This function is now simplified to just update the colors
    private func updateGradient(colors: [CGColor]) {
        gradientLayer.colors = colors
    }
    
    private func addGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.54, green: 0.88, blue: 0.99, alpha: 1.00).cgColor,
            UIColor(red: 0.51, green: 0.81, blue: 0.97, alpha: 1.00).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK: - IBActions
    @IBAction func didTapAnswerButton(_ sender: UIButton) {
        guard currQuestionIndex < questions.count else { return }
        // Change this line:
        updateToNextQuestion(selectedButton: sender)
    }
}


// MARK: - String Extension
extension String {
    var decodingHTMLEntities: String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributedString.string
    }
}
