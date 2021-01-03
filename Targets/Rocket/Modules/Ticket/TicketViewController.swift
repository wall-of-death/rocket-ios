//
//  TicketViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import Endpoint
import Foundation
import UIKit

final class TicketViewController: UIViewController, Instantiable {

    typealias Input = Void
    var tickets: [Ticket] = []

    var dependencyProvider: LoggedInDependencyProvider!

    @IBOutlet weak var ticketsTableView: UITableView!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var viewModel = TicketViewModel(
        apiClient: dependencyProvider.apiClient,
        user: dependencyProvider.user,
        outputHander: { output in
            switch output {
            
            case .refreshMyTickets(let tickets):
                DispatchQueue.main.async {
                    self.tickets = tickets
                    self.setTableViewBackgroundView(tableView: self.ticketsTableView)
                    self.ticketsTableView.reloadData()
                }
            case .getMyTickets(let tickets):
                DispatchQueue.main.async {
                    self.tickets += tickets
                    self.setTableViewBackgroundView(tableView: self.ticketsTableView)
                    self.ticketsTableView.reloadData()
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    func setup() {
        title = "Ticket"
        self.view.backgroundColor = Brand.color(for: .background(.primary))

        ticketsTableView.delegate = self
        ticketsTableView.dataSource = self
        ticketsTableView.registerCellClass(LiveCell.self)
        ticketsTableView.backgroundColor = .clear
        
        ticketsTableView.refreshControl = BrandRefreshControl()
        ticketsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshMyTickets(sender:)), for: .valueChanged)
        
        self.getMyTickets()
    }
    
    private func getMyTickets() {
        viewModel.getMyTickets()
    }
    
    @objc private func refreshMyTickets(sender: UIRefreshControl) {
        viewModel.refreshMyTickets()
        sender.endRefreshing()
    }
}

extension TicketViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tickets.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let live = self.tickets[indexPath.section].live
        let cell = tableView.dequeueReusableCell(LiveCell.self, input: live, for: indexPath)
        cell.listen { [weak self] output in
            switch output {
            case .listenButtonTapped: self?.listenButtonTapped(cellIndex: indexPath.section)
            case .buyTicketButtonTapped: self?.buyTicketButtonTapped(cellIndex: indexPath.section)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 60 : 16
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let view = UIView(
                frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 60))
            let titleBaseView = UIView(frame: CGRect(x: 16, y: 16, width: 300, height: 40))
            let titleView = TitleLabelView(
                input: (
                    title: "TICKETS", font: Brand.font(for: .xlargeStrong), color: Brand.color(for: .text(.primary))
                ))
            titleBaseView.addSubview(titleView)
            view.addSubview(titleBaseView)
            return view
        default:
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ticket = self.tickets[indexPath.section]
        let vc = LiveDetailViewController(dependencyProvider: self.dependencyProvider, input: ticket.live)
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (self.tickets.count - indexPath.section) == 2 && self.tickets.count % per == 0 {
            self.getMyTickets()
        }
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .ticket, actionButtonTitle: "バンドを探す")
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            emptyCollectionView.listen {
                self.didSearchButtonTapped()
            }
            return emptyCollectionView
        }()
        tableView.backgroundView = tickets.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
    
    func didSearchButtonTapped() {
        self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers![2]
    }

    private func listenButtonTapped(cellIndex: Int) {
        print("listen \(cellIndex) music")
    }

    private func buyTicketButtonTapped(cellIndex: Int) {
        print("buy \(cellIndex) ticket")
    }
}
