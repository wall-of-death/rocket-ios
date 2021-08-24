//
//  BandListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/28.
//

import UIKit
import Endpoint
import Combine

final class GroupListViewController: UIViewController, Instantiable {
    typealias Input = GroupListViewModel.Input

    let dependencyProvider: LoggedInDependencyProvider
    private var groupTableView: UITableView!

    let viewModel: GroupListViewModel
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = GroupListViewModel(
            dependencyProvider: dependencyProvider,
            input: input
        )

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                self.setTableViewBackgroundView(tableView: self.groupTableView)
                self.groupTableView.reloadData()
            case .updateFollowing:
                viewModel.refresh()
            case .error(let error):
                print(error)
                self.showAlert()
            }
        }
        .store(in: &cancellables)
    }
    private func setup() {
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        groupTableView = UITableView()
        groupTableView.translatesAutoresizingMaskIntoConstraints = false
        groupTableView.showsVerticalScrollIndicator = false
        groupTableView.tableFooterView = UIView(frame: .zero)
        groupTableView.separatorStyle = .none
        groupTableView.backgroundColor = .clear
        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.registerCellClass(GroupCell.self)
        self.view.addSubview(groupTableView)
        
        groupTableView.refreshControl = BrandRefreshControl()
        groupTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)

        let constraints: [NSLayoutConstraint] = [
            groupTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            groupTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            groupTableView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            groupTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func inject(_ input: Input) {
        viewModel.inject(input)
    }
    @objc private func refreshGroups(sender: UIRefreshControl) {
        viewModel.refresh()
        sender.endRefreshing()
    }
    
    private var listener: (GroupFeed) -> Void = { _ in }
    func listen(_ listener: @escaping (GroupFeed) -> Void) {
        self.listener = listener
    }
}

extension GroupListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.state.groups.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = self.viewModel.state.groups[indexPath.row]
        let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .selfTapped:
                switch viewModel.dataSource {
                case .searchResultsToSelect(_):
                    self.listener(group)
                case .followingGroups(_), .searchResults(_), .allGroup:
                    let vc = BandDetailViewController(
                        dependencyProvider: self.dependencyProvider, input: group.group)
                    let nav = self.navigationController ?? presentingViewController?.navigationController
                    nav?.pushViewController(vc, animated: true)
                case .none: break
                }
            case .likeButtonTapped:
                viewModel.followButtonTapped(group: group)
            case .listenButtonTapped: break
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .groupList, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = self.viewModel.state.groups.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 32),
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            ])
        }
    }
}

extension GroupListViewController: PageContent {
    var scrollView: UIScrollView {
        _ = view
        return self.groupTableView
    }
}
