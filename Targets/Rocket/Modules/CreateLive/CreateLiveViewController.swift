//
//  CreateLiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/23.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import UIKit

final class CreateLiveViewController: UIViewController, Instantiable {
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
    private lazy var liveTitleInputView: TextFieldView = {
        let liveTitleInputView = TextFieldView(input: (section: "タイトル", text: nil, maxLength: 32))
        liveTitleInputView.translatesAutoresizingMaskIntoConstraints = false
        return liveTitleInputView
    }()
    private lazy var hostGroupInputView: TextFieldView = {
        let inputView = TextFieldView(input: (section: "主催バンド", text: nil, maxLength: 40))
        inputView.translatesAutoresizingMaskIntoConstraints = false
        return inputView
    }()
    private lazy var hostGroupPickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.dataSource = self
        pickerView.delegate = self
        return pickerView
    }()
    private lazy var liveStyleInputView: TextFieldView = {
        let liveStyleInputView = TextFieldView(input: (section: "ライブ形式", text: nil, maxLength: 10))
        liveStyleInputView.translatesAutoresizingMaskIntoConstraints = false
        return liveStyleInputView
    }()
    private lazy var liveStylePickerView: UIPickerView = {
        let liveStylePickerView = UIPickerView()
        liveStylePickerView.translatesAutoresizingMaskIntoConstraints = false
        liveStylePickerView.dataSource = self
        liveStylePickerView.delegate = self
        return liveStylePickerView
    }()
    private lazy var livePriceInputView: TextFieldView = {
        let livePriceInputView = TextFieldView(input: (section: "チケット料金", text: nil, maxLength: 12))
        livePriceInputView.translatesAutoresizingMaskIntoConstraints = false
        livePriceInputView.keyboardType(.numberPad)
        return livePriceInputView
    }()
    private lazy var livehouseInputView: TextFieldView = {
        let livehouseInputView = TextFieldView(input: (section: "会場", text: nil, maxLength: 40))
        livehouseInputView.translatesAutoresizingMaskIntoConstraints = false
        return livehouseInputView
    }()
    private lazy var livehousePickerView: UIPickerView = {
        let livehousePickerView = UIPickerView()
        livehousePickerView.translatesAutoresizingMaskIntoConstraints = false
        livehousePickerView.dataSource = self
        livehousePickerView.delegate = self
        return livehousePickerView
    }()
    private lazy var performersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()
    private lazy var addPerformerButton: PrimaryButton = {
        let button = PrimaryButton(text: "対バン相手を追加する")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(addPerformerButtonTapped(_:)), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    private lazy var openTimeInputView: DateInputView = {
        let dateInputView = DateInputView(section: "オープン時間")
        dateInputView.translatesAutoresizingMaskIntoConstraints = false
        return dateInputView
    }()
    private lazy var startTimeInputView: DateInputView = {
        let dateInputView = DateInputView(section: "スタート時間")
        dateInputView.translatesAutoresizingMaskIntoConstraints = false
        return dateInputView
    }()
    private lazy var endTimeInputView: DateInputView = {
        let dateInputView = DateInputView(section: "クローズ時間")
        dateInputView.translatesAutoresizingMaskIntoConstraints = false
        return dateInputView
    }()
    private var thumbnailInputView: UIView = {
        let thumbnailInputView = UIView()
        thumbnailInputView.translatesAutoresizingMaskIntoConstraints = false
        
        return thumbnailInputView
    }()
    private lazy var profileImageView: UIImageView = {
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 16
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
        let registerButton = PrimaryButton(text: "ライブ作成")
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.layer.cornerRadius = 25
        registerButton.isEnabled = false
        return registerButton
    }()

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日 HH:mm"
        return dateFormatter
    }()
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: CreateLiveViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = CreateLiveViewModel(dependencyProvider: dependencyProvider)

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
            .sink(receiveValue: viewModel.didRegisterButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didCreateLive(_):
                self.dismiss(animated: true, completion: nil)
            case .didGetMemberships(let memberships):
                if !memberships.isEmpty {
                    self.hostGroupInputView.setText(text: memberships[0].name)
                    self.hostGroupPickerView.reloadAllComponents()
                } else {
                    let alertController = UIAlertController(
                        title: "バンドに所属していません", message: "先にバンドを作成するかバンドに所属してください", preferredStyle: UIAlertController.Style.alert)

                    let cancelAction = UIAlertAction(
                        title: "OK", style: UIAlertAction.Style.cancel,
                        handler: { action in
                            self.dismiss(animated: true, completion: nil)
                        })
                    alertController.addAction(cancelAction)

                    self.present(alertController, animated: true, completion: nil)
                }
            case .didUpdatePerformers(let performers):
                performersStackView.arrangedSubviews.forEach {
                    performersStackView.removeArrangedSubview($0)
                    $0.removeFromSuperview()
                }
                performers.enumerated().forEach { (cellIndex, performer) in
                    let cellContent = GroupBannerCell()
                    cellContent.update(input: performer)
                    cellContent.listen { [unowned self] in
                        performerTapped(cellIndex: cellIndex)
                    }
                    performersStackView.addArrangedSubview(cellContent)
                }
                performersStackView.isHidden = performers.isEmpty
            case .didUpdateLiveStyle(let liveStyle):
                switch liveStyle {
                case .oneman(_):
                    performersStackView.isHidden = true
                    addPerformerButton.isHidden = true
                case .battle(_):
                    performersStackView.isHidden = false
                    addPerformerButton.isHidden = false
                case .festival(_):
                    performersStackView.isHidden = false
                    addPerformerButton.isHidden = false
                default:
                    break
                }
            case .didUpdateDatePickers(let pickerType):
                openTimeInputView.date = viewModel.state.openAt
                startTimeInputView.date = viewModel.state.startAt
                endTimeInputView.date = viewModel.state.endAt
                switch pickerType {
                case .openAt(let openAt):
                    startTimeInputView.maximumDate = openAt
                    endTimeInputView.maximumDate = openAt
                case .startAt(let startAt):
                    endTimeInputView.maximumDate = startAt
                default:
                    break
                }
            case .updateSubmittableState(let isSubmittable):
                self.registerButton.isEnabled = isSubmittable
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
            }
        }
        .store(in: &cancellables)
        
        liveTitleInputView.listen { [unowned self] in
            didInputValue()
        }
        
        hostGroupInputView.listen { [unowned self] in
            hostGroupInputView.setText(text: self.viewModel.state.memberships[self.hostGroupPickerView.selectedRow(inComponent: 0)].name)
            didInputValue()
        }
        
        liveStyleInputView.listen { [unowned self] in
            liveStyleInputView.setText(text: self.viewModel.state.socialInputs.liveStyles[self.liveStylePickerView.selectedRow(inComponent: 0)])
            didInputValue()
        }
        
        livePriceInputView.listen { [unowned self] in
            didInputValue()
        }
        
        livehouseInputView.listen { [unowned self] in
            livehouseInputView.setText(text: self.viewModel.state.socialInputs.livehouses[self.livehousePickerView.selectedRow(inComponent: 0)])
            didInputValue()
        }
        
        openTimeInputView.listen { [unowned self] in
            viewModel.didUpdateDatePicker(pickerType: .openAt(openTimeInputView.date))
        }
        
        startTimeInputView.listen { [unowned self] in
            viewModel.didUpdateDatePicker(pickerType: .startAt(startTimeInputView.date))
        }
        
        endTimeInputView.listen { [unowned self] in
            viewModel.didUpdateDatePicker(pickerType: .endAt(endTimeInputView.date))
        }
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "ライブ作成"
        self.navigationItem.largeTitleDisplayMode = .never
        
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
        
        mainView.addArrangedSubview(liveTitleInputView)
        NSLayoutConstraint.activate([
            liveTitleInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(hostGroupInputView)
        hostGroupInputView.selectInputView(inputView: hostGroupPickerView)
        NSLayoutConstraint.activate([
            hostGroupInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])

        mainView.addArrangedSubview(liveStyleInputView)
        liveStyleInputView.selectInputView(inputView: liveStylePickerView)
        NSLayoutConstraint.activate([
            liveStyleInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(livePriceInputView)
        NSLayoutConstraint.activate([
            livePriceInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])

        mainView.addArrangedSubview(livehouseInputView)
        livehouseInputView.selectInputView(inputView: livehousePickerView)
        NSLayoutConstraint.activate([
            livehouseInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])

        mainView.addArrangedSubview(performersStackView)
        mainView.addArrangedSubview(addPerformerButton)
        NSLayoutConstraint.activate([
            addPerformerButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        mainView.addArrangedSubview(openTimeInputView)
        NSLayoutConstraint.activate([
            openTimeInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(startTimeInputView)
        NSLayoutConstraint.activate([
            startTimeInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(endTimeInputView)
        NSLayoutConstraint.activate([
            endTimeInputView.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        mainView.addArrangedSubview(thumbnailInputView)
        NSLayoutConstraint.activate([
            thumbnailInputView.heightAnchor.constraint(equalToConstant: 200),
        ])
        
        thumbnailInputView.addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.heightAnchor.constraint(equalToConstant: 180),
            profileImageView.topAnchor.constraint(equalTo: thumbnailInputView.topAnchor),
            profileImageView.rightAnchor.constraint(equalTo: thumbnailInputView.rightAnchor),
            profileImageView.leftAnchor.constraint(equalTo: thumbnailInputView.leftAnchor),
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
        
        liveTitleInputView.focus()
    }
    
    private func didInputValue() {
        let title = liveTitleInputView.getText()
        let liveStyle = liveStyleInputView.getText()
        let price: Int? = {
            if let priceText = livePriceInputView.getText() {
                return Int(priceText)
            } else { return nil }
        }()
        let hostGroupId = {
            return !self.viewModel.state.memberships.isEmpty ?
            self.viewModel.state.memberships[self.hostGroupPickerView.selectedRow(inComponent: 0)].id : nil
        }()
        let livehouse = livehouseInputView.getText()
        
        viewModel.didUpdateInputItems(title: title, hostGroup: hostGroupId, liveStyle: liveStyle, price: price, livehouse: livehouse)
    }

    @objc private func addPerformerButtonTapped(_ sender: Any) {
        let vc = SelectPerformersViewController(dependencyProvider: dependencyProvider, input: viewModel.state.performers)
        vc.listen { [unowned self] group in
            viewModel.didAddPerformer(performer: group)
        }
        present(vc, animated: true, completion: nil)
    }
    
    private func performerTapped(cellIndex: Int) {
        let alertController = UIAlertController(
            title: "削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                viewModel.didRemovePerformer(performer: viewModel.state.performers[cellIndex])
            })
        let cancelAction = UIAlertAction(
            title: "キャンセル", style: UIAlertAction.Style.cancel,
            handler: { action in
                print("close")
            })
        alertController.addAction(acceptAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
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

extension CreateLiveViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        profileImageView.image = image
        viewModel.didUpdateArtwork(thumbnail: image)
        self.dismiss(animated: true, completion: nil)
    }
}

extension CreateLiveViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String?
    {
        switch pickerView {
        case self.hostGroupPickerView:
            return viewModel.state.memberships[row].name
        case self.liveStylePickerView:
            return viewModel.state.socialInputs.liveStyles[row]
        case self.livehousePickerView:
            return viewModel.state.socialInputs.livehouses[row]
        default:
            return "yo"
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case self.hostGroupPickerView:
            return viewModel.state.memberships.count
        case self.liveStylePickerView:
            return viewModel.state.socialInputs.liveStyles.count
        case self.livehousePickerView:
            return viewModel.state.socialInputs.livehouses.count
        default:
            return 1
        }
    }
}
