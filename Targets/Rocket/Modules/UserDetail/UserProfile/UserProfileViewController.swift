//
//  UserProfileViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/01.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import InternalDomain
import ImageViewer
import TagListView

final class UserProfileViewController: UIViewController, Instantiable {
    typealias Input = User
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: UserProfileViewModel
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var verticalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    
    private let recentlyFollowingSectionHeader = SummarySectionHeader(title: "最近好きなアーティスト")
    private lazy var recentlyFollowingContent: TagListView = {
        let content = TagListView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.alignment = .left
        content.cornerRadius = 16
        content.paddingY = 8
        content.paddingX = 12
        content.marginX = 8
        content.marginY = 8
        content.textFont = Brand.font(for: .medium)
        return content
    }()
    private lazy var recentlyFollowingWrapper: UIView = Self.addPadding(to: self.recentlyFollowingContent)
    
    private let followingSectionHeader = SummarySectionHeader(title: "好きなアーティスト")
    private lazy var followingContent: TagListView = {
        let content = TagListView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.alignment = .left
        content.cornerRadius = 16
        content.paddingY = 8
        content.paddingX = 12
        content.marginX = 8
        content.marginY = 8
        content.textFont = Brand.font(for: .medium)
        return content
    }()
    private lazy var followingWrapper: UIView = Self.addPadding(to: self.followingContent)
    
    private let liveScheduleSectionHeader = SummarySectionHeader(title: "参戦予定")
    private lazy var liveScheduleTableView: LiveScheduleTableView = {
        let content = LiveScheduleTableView(liveFeeds: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isScrollEnabled = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 76 * 3),
        ])
        return content
    }()
    
    private static func addPadding(to view: UIView) -> UIView {
        let paddingView = UIView()
        paddingView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: paddingView.leftAnchor, constant: 16),
            paddingView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 16),
            view.topAnchor.constraint(equalTo: paddingView.topAnchor),
            view.bottomAnchor.constraint(equalTo: paddingView.bottomAnchor),
        ])
        return paddingView
    }
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = UserProfileViewModel(dependencyProvider: dependencyProvider, input: input)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        viewModel.viewDidLoad()
    }
    
    override func loadView() {
        view = verticalScrollView
        view.backgroundColor = Brand.color(for: .background(.primary))
        view.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: scrollStackView.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollStackView.bottomAnchor),
            view.leftAnchor.constraint(equalTo: scrollStackView.leftAnchor),
            view.rightAnchor.constraint(equalTo: scrollStackView.rightAnchor),
        ])
        
        scrollStackView.addArrangedSubview(recentlyFollowingSectionHeader)
        NSLayoutConstraint.activate([
            recentlyFollowingSectionHeader.heightAnchor.constraint(equalToConstant: 64),
            recentlyFollowingSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        recentlyFollowingWrapper.isHidden = true
        scrollStackView.addArrangedSubview(recentlyFollowingWrapper)
        
        scrollStackView.addArrangedSubview(followingSectionHeader)
        NSLayoutConstraint.activate([
            followingSectionHeader.heightAnchor.constraint(equalToConstant: 64),
            followingSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        followingWrapper.isHidden = true
        scrollStackView.addArrangedSubview(followingWrapper)
        
        scrollStackView.addArrangedSubview(liveScheduleSectionHeader)
        NSLayoutConstraint.activate([
            liveScheduleSectionHeader.heightAnchor.constraint(equalToConstant: 64),
            liveScheduleSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        liveScheduleTableView.isHidden = true
        scrollStackView.addArrangedSubview(liveScheduleTableView)
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] output in
            switch output {
            case .didGetFollowing(let groupFeeds):
                followingWrapper.isHidden = false
                followingContent.removeAllTags()
                if groupFeeds.isEmpty {
                    followingContent.addTag("いません")
                    followingContent.tagBackgroundColor = Brand.color(for: .background(.cellSelected))
                } else {
                    followingContent.addTags(groupFeeds.map { $0.group.name })
                    followingContent.tagBackgroundColor = Brand.color(for: .text(.link))
                }
            case .didGetRecentlyFollowing(let groupFeeds):
                recentlyFollowingWrapper.isHidden = false
                recentlyFollowingContent.removeAllTags()
                if groupFeeds.isEmpty {
                    recentlyFollowingContent.addTag("いません")
                    recentlyFollowingContent.tagBackgroundColor = Brand.color(for: .background(.cellSelected))
                } else {
                    recentlyFollowingContent.addTags(groupFeeds.map { $0.group.name })
                    recentlyFollowingContent.tagBackgroundColor = Brand.color(for: .text(.toggle))
                }
            case .didGetLiveSchedule(let liveFeeds):
                liveScheduleTableView.isHidden = false
                liveScheduleTableView.inject(liveFeeds: liveFeeds)
            case .reportError(let err):
                print(String(describing: err))
                showAlert()
            }
        })
        .store(in: &cancellables)
        
        recentlyFollowingSectionHeader.listen { [unowned self] in
            let vc = GroupListViewController(dependencyProvider: dependencyProvider, input: .group(viewModel.state.recentlyFollowingGroups))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        followingSectionHeader.listen { [unowned self] in
            let vc = GroupListViewController(dependencyProvider: dependencyProvider, input: .followingGroups(viewModel.state.user.id))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        liveScheduleSectionHeader.listen { [unowned self] in
            let vc = LiveListViewController(dependencyProvider: dependencyProvider, input: .likedFutureLive(viewModel.state.user.id))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        liveScheduleTableView.listen { [unowned self] live in
            let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: live.live)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension UserProfileViewController: PageContent {
    var scrollView: UIScrollView {
        _ = view
        return self.verticalScrollView
    }
}