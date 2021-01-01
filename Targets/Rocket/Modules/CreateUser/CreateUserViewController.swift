//
//  CreateUserViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/31.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import UIKit

final class CreateUserViewController: UIViewController, Instantiable {
    typealias Input = Void

    private lazy var verticalScrollView: UIScrollView = {
        let verticalScrollView = UIScrollView()
        verticalScrollView.translatesAutoresizingMaskIntoConstraints = false
        verticalScrollView.backgroundColor = .clear
        verticalScrollView.showsVerticalScrollIndicator = false
        return verticalScrollView
    }()
    private lazy var mainView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 48
        return stackView
    }()
    private lazy var userRoleContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    private lazy var userRoleSummaryView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 48
        return stackView
    }()
    private lazy var fanRoleSummaryView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let fanImageView = UIImageView()
        fanImageView.translatesAutoresizingMaskIntoConstraints = false
        fanImageView.image = UIImage(named: "selectedGuitarIcon")
        view.addSubview(fanImageView)
        NSLayoutConstraint.activate([
            fanImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            fanImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fanImageView.widthAnchor.constraint(equalToConstant: 60),
            fanImageView.heightAnchor.constraint(equalTo: fanImageView.widthAnchor),
        ])

        let fanTitleLabel = UILabel()
        fanTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        fanTitleLabel.text = "ファン"
        fanTitleLabel.textAlignment = .center
        fanTitleLabel.font = Brand.font(for: .mediumStrong)
        fanTitleLabel.textColor = Brand.color(for: .text(.primary))
        view.addSubview(fanTitleLabel)
        NSLayoutConstraint.activate([
            fanTitleLabel.topAnchor.constraint(equalTo: fanImageView.bottomAnchor),
            fanTitleLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
            fanTitleLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            fanTitleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
        ])

        let fanSectionButton = UIButton()
        fanSectionButton.translatesAutoresizingMaskIntoConstraints = false
        fanSectionButton.translatesAutoresizingMaskIntoConstraints = false
        fanSectionButton.addTarget(
            self, action: #selector(fanSectionButtonTapped(_:)), for: .touchUpInside)
        view.addSubview(fanSectionButton)
        NSLayoutConstraint.activate([
            fanSectionButton.topAnchor.constraint(equalTo: view.topAnchor),
            fanSectionButton.rightAnchor.constraint(equalTo: view.rightAnchor),
            fanSectionButton.leftAnchor.constraint(equalTo: view.leftAnchor),
            fanSectionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        return view
    }()
    private lazy var artistRoleSummaryView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let bandImageView = UIImageView()
        bandImageView.translatesAutoresizingMaskIntoConstraints = false
        bandImageView.image = UIImage(named: "selectedMusicIcon")
        view.addSubview(bandImageView)
        NSLayoutConstraint.activate([
            bandImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            bandImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bandImageView.widthAnchor.constraint(equalToConstant: 60),
            bandImageView.heightAnchor.constraint(equalTo: bandImageView.widthAnchor),
        ])

        let bandTitleLabel = UILabel()
        bandTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        bandTitleLabel.text = "メンバー"
        bandTitleLabel.textAlignment = .center
        bandTitleLabel.font = Brand.font(for: .mediumStrong)
        bandTitleLabel.textColor = Brand.color(for: .text(.primary))
        view.addSubview(bandTitleLabel)
        NSLayoutConstraint.activate([
            bandTitleLabel.topAnchor.constraint(equalTo: bandImageView.bottomAnchor),
            bandTitleLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
            bandTitleLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            bandTitleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
        ])

        let bandSectionButton = UIButton()
        bandSectionButton.translatesAutoresizingMaskIntoConstraints = false
        bandSectionButton.addTarget(
            self, action: #selector(bandSectionButtonTapped(_:)), for: .touchUpInside)
        
        view.addSubview(bandSectionButton)
        NSLayoutConstraint.activate([
            bandSectionButton.topAnchor.constraint(equalTo: view.topAnchor),
            bandSectionButton.rightAnchor.constraint(equalTo: view.rightAnchor),
            bandSectionButton.leftAnchor.constraint(equalTo: view.leftAnchor),
            bandSectionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        return view
    }()
    private lazy var displayNameInputView: TextFieldView = {
        let displayNameInputView = TextFieldView(input: (section: "表示名", text: nil, maxLength: 20))
        displayNameInputView.translatesAutoresizingMaskIntoConstraints = false
        return displayNameInputView
    }()
    private lazy var partInputView: TextFieldView = {
        let partInputView = TextFieldView(input: (section: "パート", text: nil, maxLength: 20))
        partInputView.translatesAutoresizingMaskIntoConstraints = false
        return partInputView
    }()
    private lazy var partPickerView: UIPickerView = {
        let partPickerView = UIPickerView()
        partPickerView.translatesAutoresizingMaskIntoConstraints = false
        partPickerView.dataSource = self
        partPickerView.delegate = self
        return partPickerView
    }()
    private var thumbnailInputView: UIView = {
        let thumbnailInputView = UIView()
        thumbnailInputView.translatesAutoresizingMaskIntoConstraints = false
        
        return thumbnailInputView
    }()
    private lazy var profileImageView: UIImageView = {
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 60
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "human")
        profileImageView.contentMode = .scaleAspectFill
        return profileImageView
    }()
    private lazy var changeProfileImageButton: UIButton = {
        let changeProfileImageButton = UIButton()
        changeProfileImageButton.translatesAutoresizingMaskIntoConstraints = false
        changeProfileImageButton.addTarget(
            self, action: #selector(selectProfileImage(_:)), for: .touchUpInside)
        return changeProfileImageButton
    }()
    private lazy var profileImageTitle: UILabel = {
        let profileImageTitle = UILabel()
        profileImageTitle.translatesAutoresizingMaskIntoConstraints = false
        profileImageTitle.text = "プロフィール画像"
        profileImageTitle.textAlignment = .center
        profileImageTitle.font = Brand.font(for: .medium)
        profileImageTitle.textColor = Brand.color(for: .text(.primary))
        return profileImageTitle
    }()
    private lazy var registerButton: PrimaryButton = {
        let registerButton = PrimaryButton(text: "ユーザー作成")
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.layer.cornerRadius = 25
        registerButton.isEnabled = false
        return registerButton
    }()
    
    let dependencyProvider: DependencyProvider
    let viewModel: CreateUserViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = CreateUserViewModel(dependencyProvider: dependencyProvider)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        
        viewModel.viewDidLoad()
    }
    
    func bind() {
        registerButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: viewModel.didSignupButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didCreateUser(let  user):
                let loggedInDependencyProvider = LoggedInDependencyProvider(provider: dependencyProvider, user: user)
                let vc = InvitationViewController(dependencyProvider: loggedInDependencyProvider, input: ())
                self.navigationController?.pushViewController(vc, animated: true)
            case .switchUserRole(let role):
                didSwitchedRole(role: role)
            case .updateSubmittableState(let submittable):
                self.registerButton.isEnabled = submittable
            case .reportError(let error):
                showAlert(title: "エラー", message: error.localizedDescription)
            }
        }
        .store(in: &cancellables)
        
        displayNameInputView.listen {
            self.didInputValue()
        }
        
        partInputView.listen {
            self.partInputView.setText(text: self.viewModel.state.socialInputs.parts[self.partPickerView.selectedRow(inComponent: 0)])
            self.didInputValue()
        }
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        
        self.view.addSubview(verticalScrollView)
        NSLayoutConstraint.activate([
            verticalScrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            verticalScrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            verticalScrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            verticalScrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
        ])
        
        verticalScrollView.addSubview(mainView)
        NSLayoutConstraint.activate([
            mainView.topAnchor.constraint(equalTo: verticalScrollView.topAnchor),
            mainView.bottomAnchor.constraint(equalTo: verticalScrollView.bottomAnchor),
            mainView.rightAnchor.constraint(equalTo: verticalScrollView.rightAnchor),
            mainView.leftAnchor.constraint(equalTo: verticalScrollView.leftAnchor),
            mainView.centerXAnchor.constraint(equalTo: verticalScrollView.centerXAnchor),
        ])
        
        let topSpacer = UIView()
        mainView.addArrangedSubview(topSpacer) // Spacer
        NSLayoutConstraint.activate([
            topSpacer.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        mainView.addArrangedSubview(userRoleContentView)
        NSLayoutConstraint.activate([
            userRoleContentView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            userRoleContentView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            userRoleContentView.heightAnchor.constraint(equalToConstant: 100),
        ])
        
        userRoleContentView.addSubview(userRoleSummaryView)
        userRoleSummaryView.addArrangedSubview(fanRoleSummaryView)
        NSLayoutConstraint.activate([
            fanRoleSummaryView.widthAnchor.constraint(equalToConstant: 100),
            fanRoleSummaryView.heightAnchor.constraint(equalToConstant: 100),
        ])
        
        userRoleSummaryView.addArrangedSubview(artistRoleSummaryView)
        NSLayoutConstraint.activate([
            userRoleSummaryView.centerXAnchor.constraint(equalTo: userRoleContentView.centerXAnchor),
            userRoleSummaryView.centerYAnchor.constraint(equalTo: userRoleContentView.centerYAnchor),
        ])
        
        mainView.addArrangedSubview(displayNameInputView)
        NSLayoutConstraint.activate([
            displayNameInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(partInputView)
        partInputView.selectInputView(inputView: partPickerView)
        NSLayoutConstraint.activate([
            partInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(thumbnailInputView)
        NSLayoutConstraint.activate([
            thumbnailInputView.heightAnchor.constraint(equalToConstant: 150),
        ])
        
        thumbnailInputView.addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            profileImageView.topAnchor.constraint(equalTo: thumbnailInputView.topAnchor),
            profileImageView.centerXAnchor.constraint(equalTo: thumbnailInputView.centerXAnchor),
        ])
        
        thumbnailInputView.addSubview(profileImageTitle)
        NSLayoutConstraint.activate([
            profileImageTitle.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),
            profileImageTitle.rightAnchor.constraint(equalTo: thumbnailInputView.rightAnchor),
            profileImageTitle.bottomAnchor.constraint(equalTo: thumbnailInputView.bottomAnchor),
        ])
        
        thumbnailInputView.addSubview(changeProfileImageButton)
        NSLayoutConstraint.activate([
            changeProfileImageButton.topAnchor.constraint(equalTo: thumbnailInputView.topAnchor),
            changeProfileImageButton.rightAnchor.constraint(
                equalTo: thumbnailInputView.rightAnchor),
            changeProfileImageButton.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),
            changeProfileImageButton.bottomAnchor.constraint(equalTo: thumbnailInputView.bottomAnchor),
        ])
        
        mainView.addArrangedSubview(registerButton)
        NSLayoutConstraint.activate([
            registerButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        let bottomSpacer = UIView()
        mainView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
    
    private func didInputValue() {
        let displayName: String? = displayNameInputView.getText()
        let part: String? = partInputView.getText()
        let artworkImage: UIImage? = profileImageView.image
        
        viewModel.didUpdateInputItems(displayName: displayName, role: part, profileImage: artworkImage)
    }

    func didSwitchedRole(role: RoleProperties) {
        switch role {
        case .fan(_):
            fanRoleSummaryView.layer.borderWidth = 1
            fanRoleSummaryView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
            artistRoleSummaryView.layer.borderWidth = 0
            partInputView.isHidden = true
        case .artist(_):
            artistRoleSummaryView.layer.borderWidth = 1
            artistRoleSummaryView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
            fanRoleSummaryView.layer.borderWidth = 0
            partInputView.isHidden = false
        }
    }

    @objc private func fanSectionButtonTapped(_ sender: Any) {
        viewModel.switchRole(role: .fan(Fan()))
    }

    @objc private func bandSectionButtonTapped(_ sender: Any) {
        let part = partInputView.getText() ?? viewModel.state.socialInputs.parts[0]
        viewModel.switchRole(role: .artist(Artist(part: part)))
    }

    @objc private func selectProfileImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
}

extension CreateUserViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        profileImageView.image = image
        didInputValue()
        self.dismiss(animated: true, completion: nil)
    }
}

extension CreateUserViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.state.socialInputs.parts.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String?
    {
        return viewModel.state.socialInputs.parts[row]
    }
}
