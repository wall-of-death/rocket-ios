//
//  HomeViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/23.
//

import UIKit
import Combine
import Endpoint
import ImageViewer
import Parchment
import AppTrackingTransparency
import SCLAlertView

final class HomeViewController: UIViewController {
    let dependencyProvider: LoggedInDependencyProvider
    private var cancellables: [AnyCancellable] = []
    private let urlSchemeActionViewModel: UrlSchemeActionViewModel
    private let pointViewModel: PointViewModel
    
    private lazy var searchButton: UIBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "magnifyingglass"),
        style: .plain,
        target: self,
        action: #selector(searchButtonTapped)
    )
    private lazy var postButton: UIBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "plus"),
        style: .plain,
        target: self,
        action: #selector(createPostButtonTapped)
    )
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.urlSchemeActionViewModel = UrlSchemeActionViewModel(dependencyProvider: dependencyProvider)
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        urlSchemeActionViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .pushToUserDetail(let input):
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToGroupDetail(let input):
                let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToLiveDetail(let input):
                let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPostDetail(let input):
                let vc = PostDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .reportError(let err):
                print(String(describing: err))
                showAlert(title: "見つかりませんでした", message: "URLが正しいかお確かめの上再度お試しください")
            }
        }
        .store(in: &cancellables)
        
        pointViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .addPoint(_):
                showSuccess()
            default: break
            }
        }
        .store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ホーム"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        navigationItem.setRightBarButtonItems([
            searchButton,
            postButton,
        ], animated: false)
        
        setPagingViewController()
        requestNotification()
        showWalkThrough()
        if #available(iOS 14, *) {
            checkTrackingAuthorizationStatus()
        }
        actForUrlScheme()
        
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    private func setPagingViewController() {
        let vc1 = PostListViewController(dependencyProvider: dependencyProvider, input: .followingPost)
        let vc2 = PostListViewController(dependencyProvider: dependencyProvider, input: .trendPost)
        let pagingViewController = PagingViewController(viewControllers: [
            vc1,
            vc2,
        ])
        self.addChild(pagingViewController)
        self.view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        pagingViewController.menuBackgroundColor = Brand.color(for: .background(.primary))
        pagingViewController.borderColor = .clear
        pagingViewController.selectedTextColor = Brand.color(for: .brand(.primary))
        pagingViewController.indicatorColor = Brand.color(for: .brand(.primary))
        pagingViewController.textColor = Brand.color(for: .text(.primary))
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagingViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            pagingViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pagingViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }
    
    private func requestNotification() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [
            .alert, .sound, .badge,
        ]) {
            granted, error in
            if let error = error {
                DispatchQueue.main.async {
                    print(error)
                    self.showAlert()
                }
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    @available(iOS 14, *)
    func checkTrackingAuthorizationStatus() {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined:
            requestTrackingAuthorization()
        case .restricted:
            updateTrackingAuthorizationStatus(false)
        case .denied:
            updateTrackingAuthorizationStatus(false)
        case .authorized:
            updateTrackingAuthorizationStatus(true)
        @unknown default:
            fatalError()
        }
    }

    @available(iOS 14, *)
    func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .notDetermined: break
            case .restricted:
                self.updateTrackingAuthorizationStatus(false)
            case .denied:
                self.updateTrackingAuthorizationStatus(false)
            case .authorized:
                self.updateTrackingAuthorizationStatus(true)
            @unknown default:
                fatalError()
            }
        }
    }

    func updateTrackingAuthorizationStatus(_ b: Bool) {
    }
    
    private func showWalkThrough() {
        let userDefaults = UserDefaults.standard
        let key = "walkThroughPresented_v3.2.0.\(UUID.init().uuidString)"
        if !userDefaults.bool(forKey: key) {
            let vc = WalkThroughViewController(dependencyProvider: dependencyProvider)
            let nav = DismissionSubscribableNavigationController(rootViewController: vc)
            present(nav, animated: true, completion: nil)
            userDefaults.setValue(true, forKey: key)
            userDefaults.synchronize()
            nav.subscribeDismission { [unowned self] in
                presentPoint()
            }
        }
    }
    
    private func presentPoint() {
        let userDefaults = UserDefaults.standard
        let key = "pointPresented_v3.2.0.\(UUID.init().uuidString)"
        if !userDefaults.bool(forKey: key) {
            pointViewModel.addPoint(point: 2000)
            userDefaults.setValue(true, forKey: key)
            userDefaults.synchronize()
        }
    }
    
    private func showSuccess() {
        let alertView = SCLAlertView()
        alertView.showSuccess("ポイントプレゼント", subTitle: "2,000ポイント受り取ました！お気に入りのアーティストにチップを投げてみよう！ポイントはアプリ内のシェアボタンからTwitterにシェアすると増えるよ！")
    }
    
    private func actForUrlScheme() {
        if let url = dependencyProvider.urlScheme {
            urlSchemeActionViewModel.action(url: url)
        }
    }
    
    @objc private func createPostButtonTapped() {
        let vc = SearchLiveViewController(dependencyProvider: dependencyProvider)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func searchButtonTapped() {
        let vc = SearchViewController(dependencyProvider: dependencyProvider)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension HomeViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
}
