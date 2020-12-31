//
//  SearchViewController_V1.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/29.
//

import UIKit

final class SearchViewController_V1: UIViewController, Instantiable {
    typealias Input = Void
    var dependencyProvider: LoggedInDependencyProvider!

    enum Choice {
        case live
        case band
    }

    private var choice: Choice = .live

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var liveChoiceView: UIView!
    @IBOutlet weak var bandChoiceView: UIView!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    func setup() {
        title = "Search"
        self.view.backgroundColor = Brand.color(for: .background(.primary))

        searchBar.delegate = self
        searchBar.barTintColor = Brand.color(for: .background(.primary))
        searchBar.searchTextField.placeholder = "バンド・ライブを探す"
        searchBar.searchTextField.textColor = Brand.color(for: .text(.primary))
        searchBar.showsSearchResultsButton = false

        let liveImageView = UIImageView()
        liveImageView.translatesAutoresizingMaskIntoConstraints = false
        liveImageView.image = UIImage(named: "selectedGuitarIcon")
        liveChoiceView.addSubview(liveImageView)

        let liveTextLabel = UILabel()
        liveTextLabel.translatesAutoresizingMaskIntoConstraints = false
        liveTextLabel.text = "ライブ"
        liveTextLabel.font = Brand.font(for: .medium)
        liveTextLabel.textColor = Brand.color(for: .text(.primary))
        liveChoiceView.addSubview(liveTextLabel)

        let liveChoiceButton = UIButton()
        liveChoiceButton.translatesAutoresizingMaskIntoConstraints = false
        liveChoiceButton.backgroundColor = .clear
        liveChoiceButton.addTarget(
            self, action: #selector(liveChoiceButtonTapped(_:)), for: .touchUpInside)
        liveChoiceView.addSubview(liveChoiceButton)

        let bandImageView = UIImageView()
        bandImageView.translatesAutoresizingMaskIntoConstraints = false
        bandImageView.image = UIImage(named: "selectedMusicIcon")
        bandChoiceView.addSubview(bandImageView)

        let bandTextLabel = UILabel()
        bandTextLabel.translatesAutoresizingMaskIntoConstraints = false
        bandTextLabel.text = "バンド"
        bandTextLabel.font = Brand.font(for: .medium)
        bandTextLabel.textColor = Brand.color(for: .text(.primary))
        bandChoiceView.addSubview(bandTextLabel)

        let bandChoiceButton = UIButton()
        bandChoiceButton.translatesAutoresizingMaskIntoConstraints = false
        bandChoiceButton.backgroundColor = .clear
        bandChoiceButton.addTarget(
            self, action: #selector(bandChoiceButtonTapped(_:)), for: .touchUpInside)
        bandChoiceView.addSubview(bandChoiceButton)

        toggleSetting()

        let constraints = [
            liveImageView.widthAnchor.constraint(equalToConstant: 40),
            liveImageView.heightAnchor.constraint(equalToConstant: 40),
            liveImageView.centerXAnchor.constraint(equalTo: liveChoiceView.centerXAnchor),
            liveImageView.topAnchor.constraint(equalTo: liveChoiceView.topAnchor, constant: 32),

            liveTextLabel.topAnchor.constraint(equalTo: liveImageView.bottomAnchor, constant: 4),
            liveTextLabel.centerXAnchor.constraint(equalTo: liveImageView.centerXAnchor),

            liveChoiceButton.topAnchor.constraint(equalTo: liveChoiceView.topAnchor),
            liveChoiceButton.bottomAnchor.constraint(equalTo: liveChoiceView.bottomAnchor),
            liveChoiceButton.rightAnchor.constraint(equalTo: liveChoiceView.rightAnchor),
            liveChoiceButton.leftAnchor.constraint(equalTo: liveChoiceView.leftAnchor),

            bandImageView.widthAnchor.constraint(equalToConstant: 40),
            bandImageView.heightAnchor.constraint(equalToConstant: 40),
            bandImageView.centerXAnchor.constraint(equalTo: bandChoiceView.centerXAnchor),
            bandImageView.topAnchor.constraint(equalTo: bandChoiceView.topAnchor, constant: 32),

            bandTextLabel.topAnchor.constraint(equalTo: bandImageView.bottomAnchor, constant: 4),
            bandTextLabel.centerXAnchor.constraint(equalTo: bandImageView.centerXAnchor),

            bandChoiceButton.topAnchor.constraint(equalTo: bandChoiceView.topAnchor),
            bandChoiceButton.bottomAnchor.constraint(equalTo: bandChoiceView.bottomAnchor),
            bandChoiceButton.rightAnchor.constraint(equalTo: bandChoiceView.rightAnchor),
            bandChoiceButton.leftAnchor.constraint(equalTo: bandChoiceView.leftAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func toggleSetting(_ choice: Choice = .live) {
        self.choice = choice

        switch self.choice {
        case .live:
            bandChoiceView.layer.borderWidth = 0
            liveChoiceView.layer.borderWidth = 1
            liveChoiceView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        case .band:
            liveChoiceView.layer.borderWidth = 0
            bandChoiceView.layer.borderWidth = 1
            bandChoiceView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        }
    }

    @objc private func liveChoiceButtonTapped(_ sender: Any) {
        toggleSetting(.live)
    }

    @objc private func bandChoiceButtonTapped(_ sender: Any) {
        toggleSetting(.band)
    }

    @objc private func datePickerValueChanged(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}

extension SearchViewController_V1: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        switch self.choice {
        case .band:
            let vc = GroupListViewController(dependencyProvider: dependencyProvider, input: .searchResults(searchBar.text!))
            self.navigationController?.pushViewController(vc, animated: true)
        case .live:
            let vc = LiveListViewController(dependencyProvider: dependencyProvider, input: .searchResult(searchBar.text!))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        searchBar.resignFirstResponder()
    }
}