//
//  UserInformationView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import Foundation
import UIKit
import Endpoint

class UserInformationView: UIView {
    public typealias Input = UserDetailHeaderView.Input
    
    private lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 40
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var displayNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .largeStrong)
        return label
    }()
    
    private lazy var followerCountSumamryView: CountSummaryView = {
        let summaryView = CountSummaryView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(followersSummaryViewTapped))
        )
        return summaryView
    }()
    
    private lazy var followingUserCountSummaryView: CountSummaryView = {
        let summaryView = CountSummaryView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(followingUserSummaryViewTapped))
        )
        return summaryView
    }()
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func update(input: Input) {
        displayNameLabel.text = input.userDetail.name
        followerCountSumamryView.update(input: (title: "フォロワー", count: input.userDetail.followersCount))
        followingUserCountSummaryView.update(input: (title: "フォロー", count: input.userDetail.followingUsersCount))
        input.imagePipeline.loadImage(URL(string: input.userDetail.thumbnailURL!)!, into: profileImageView)
    }
    
    private func setup() {
        backgroundColor = .clear
        
        addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),
            profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            profileImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
        ])
        
        addSubview(displayNameLabel)
        NSLayoutConstraint.activate([
            displayNameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            displayNameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8),
            displayNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
        ])
        
        addSubview(followerCountSumamryView)
        NSLayoutConstraint.activate([
            followerCountSumamryView.heightAnchor.constraint(equalToConstant: 60),
            followerCountSumamryView.widthAnchor.constraint(equalToConstant: 120),
            followerCountSumamryView.topAnchor.constraint(equalTo: displayNameLabel.bottomAnchor, constant: 12),
            followerCountSumamryView.leftAnchor.constraint(equalTo: displayNameLabel.leftAnchor),
        ])
        
        addSubview(followingUserCountSummaryView)
        NSLayoutConstraint.activate([
            followingUserCountSummaryView.heightAnchor.constraint(equalToConstant: 60),
            followingUserCountSummaryView.widthAnchor.constraint(equalToConstant: 120),
            followingUserCountSummaryView.topAnchor.constraint(equalTo: followerCountSumamryView.topAnchor),
            followingUserCountSummaryView.leftAnchor.constraint(equalTo: followerCountSumamryView.rightAnchor, constant: 8),
        ])
    }
    
    private var listener: (Output) -> Void = { listenType in }
    public func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }

    public enum Output {
        case followerCountButtonTapped
        case followingUserCountButtonTapped
        case arrowButtonTapped
    }
    
    @objc private func touchUpInsideArrowButton() {
        listener(.arrowButtonTapped)
    }
    
    @objc private func followersSummaryViewTapped() {
        listener(.followerCountButtonTapped)
    }
    
    @objc private func followingUserSummaryViewTapped() {
        listener(.followingUserCountButtonTapped)
    }
}
