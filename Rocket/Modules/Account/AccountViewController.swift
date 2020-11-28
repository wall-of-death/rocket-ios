//
//  AccountViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/29.
//

import UIKit

final class AccountViewController: UIViewController, Instantiable {
    typealias Input = Void

    var dependencyProvider: LoggedInDependencyProvider!
    var items: [AccountSettingItem] = []

    private var tableView: UITableView!
    private var profileSettingItem: AccountSettingItem!
    private var seeRequestsItem: AccountSettingItem!
    private var createBandItem: AccountSettingItem!
    private var membershipItem: AccountSettingItem!
    private var logoutItem: AccountSettingItem!

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

    lazy var viewModel = AccountViewModel(
        apiClient: dependencyProvider.apiClient,
        user: dependencyProvider.user,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .inviteGroup(let invitation):
                DispatchQueue.main.async {
                    self.showInviteCode(invitationCode: invitation.id)
                }
            case .error(let error):
                print(error)
            }
        }
    )

    func setup() {
        self.view.translatesAutoresizingMaskIntoConstraints = false

        profileSettingItem = AccountSettingItem(
            title: "プロフィール設定", image: UIImage(named: "profile"), action: self.setProfile,
            hasNotification: false)
        seeRequestsItem = AccountSettingItem(
            title: "リクエスト一覧", image: UIImage(named: "mail"), action: self.seeRequests,
            hasNotification: true)
        membershipItem = AccountSettingItem(
            title: "所属バンド一覧", image: UIImage(named: "people"), action: self.memberships, hasNotification: false)
        createBandItem = AccountSettingItem(
            title: "新規バンド作成", image: UIImage(named: "selectedGuitarIcon"), action: self.createBand, hasNotification: false)
        logoutItem = AccountSettingItem(
            title: "ログアウト", image: UIImage(named: "logout"), action: self.logout,
            hasNotification: false)

        setAccountSetting()

        self.view.backgroundColor = style.color.subBackground.get()
        tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = style.color.main.get()
        tableView.register(
            UINib(nibName: "AccountCell", bundle: nil), forCellReuseIdentifier: "AccountCell")
        self.view.addSubview(tableView)

        let constraints = [
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 48),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setAccountSetting() {
        switch dependencyProvider.user.role {
        case .artist(_):
            self.items = [
                profileSettingItem,
                membershipItem,
                seeRequestsItem,
                createBandItem,
                logoutItem,
            ]
        case .fan(_):
            self.items = [
                profileSettingItem,
                logoutItem,
            ]
        }
    }

    private func setProfile() {
        let vc = EditAccountViewController(dependencyProvider: dependencyProvider, input: ())
        present(vc, animated: true, completion: nil)
    }

    private func seeRequests() {
        let vc = PerformanceRequestViewController(dependencyProvider: dependencyProvider, input: ())
        present(vc, animated: true, completion: nil)
    }
    
    private func createBand() {
        let vc = CreateBandViewController(dependencyProvider: dependencyProvider, input: ())
        present(vc, animated: true, completion: nil)
    }

    private func memberships() {
        let vc = BandListViewController(dependencyProvider: dependencyProvider, input: .memberships)
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }

    private func showInviteCode(invitationCode: String) {
        let alertController = UIAlertController(
            title: "招待コード", message: invitationCode, preferredStyle: UIAlertController.Style.alert)

        let cancelAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.cancel,
            handler: { action in
                print("close")
            })
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

    private func logout() {
        dependencyProvider.auth.signOutLocally()
        self.dismiss(animated: true, completion: nil)
        self.listener()
    }
    
    private var listener: () -> Void = {}
    func signout(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}

extension AccountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.reuse(
            AccountCell.self,
            input: (title: item.title, image: item.image, hasNotif: item.hasNotification),
            for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.action()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

struct AccountSettingItem {
    let title: String
    let image: UIImage?
    let action: () -> Void
    let hasNotification: Bool
}
