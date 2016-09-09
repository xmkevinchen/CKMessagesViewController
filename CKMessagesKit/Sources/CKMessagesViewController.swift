//
//  CKMessagesViewController.swift
//  CKCollectionViewForDataCard
//
//  Created by Kevin Chen on 8/17/16.
//  Copyright © 2016 Kevin Chen. All rights reserved.
//

import UIKit
import Reusable

open class CKMessagesViewController: UIViewController {
    
    // MARK: - Public Properties
    
    @IBOutlet public weak var messagesView: CKMessagesView!
    @IBOutlet public weak var inputToolbar: CKMessagesInputToolbar!
    
    public static var nib: UINib {
        #if swift(>=3.0)
            return UINib(nibName: String(describing:CKMessagesViewController.self), bundle: Bundle(for: CKMessagesViewController.self))
        #else
            return UINib(nibName: String(CKMessagesViewController.self), bundle: Bundle(for: CKMessagesViewController.self))
        #endif
    }
    
    public var automaticallyScrollsToMostRecentMessage: Bool = true {
        
        didSet {
            guard automaticallyScrollsToMostRecentMessage else {
                return
            }
            
            scrollToBottom(animated: true)
        }
    }
    
    public var additionalContentInsets: UIEdgeInsets = .zero {
        didSet {
            updateMessagesViewInsets()
        }
    }
    
    public var isShowingIndicator: Bool = false {
        
        didSet {
            guard isShowingIndicator != oldValue else {
                return
            }
            
            messagesView.messagesViewLayout.invalidateLayout(with: CKMessagesViewLayoutInvalidationContext.context())
            messagesView.messagesViewLayout.invalidateLayout()
        }
    }
    
    // MARK: - Private Properties
    
    fileprivate var toolbarHeight: CGFloat = 44.0
    fileprivate var registeredPresentors = [String: CKMessagePresenting.Type]()
    fileprivate var usingPresentors = [IndexPath: CKMessagePresenting]()
    fileprivate var unusedPresentors = [String: [CKMessagePresenting]]()
    fileprivate var prefetchedPresentors = [IndexPath: CKMessagePresenting]()
    
    
    // MARK: - Life Cycle
    
    deinit {
        unregisterObservers()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configure()
        registerObservers()
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        toolbarHeight = inputToolbar.preferredDefaultHeight
        view.layoutIfNeeded()
        messagesView.collectionViewLayout.invalidateLayout()
        
        if automaticallyScrollsToMostRecentMessage {
            DispatchQueue.main.async {
                self.scrollToBottom(animated: false)
                self.messagesView.messagesViewLayout.invalidateLayout(with: CKMessagesViewLayoutInvalidationContext.context())
            }
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
        
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        unusedPresentors.removeAll()
        prefetchedPresentors.removeAll()
        usingPresentors.removeAll()
        
        messagesView.collectionViewLayout.invalidateLayout()
        messagesView.setNeedsLayout()
        
    }
    

    // MARK:- Public functions
    
    public func register(presentor: CKMessagePresenting.Type, for message: CKMessageData.Type) {
        
        registeredPresentors[String(describing: message)] = presentor
        
    }
    
    
    private func configure() {
        
        #if swift(>=3.0)
            type(of:self).nib.instantiate(withOwner: self, options: nil)
        #else
            self.dynamicType.nib.instantiate(withOwner: self, options: nil)
        #endif
        
        messagesView.translatesAutoresizingMaskIntoConstraints = false
                
        messagesView.register(for: CKMessageDataViewCell.self)
        messagesView.register(for: CKMessageViewCell.self)
        messagesView.register(forSupplementaryView: UICollectionElementKindSectionFooter, for: CKMessagesIndicatorFooterView.self)
        
        messagesView.delegate = self
        messagesView.dataSource = self
                
        
        if #available(iOS 10, *) {
            messagesView.prefetchDataSource = self
        }
        
        automaticallyAdjustsScrollViewInsets = false
        automaticallyScrollsToMostRecentMessage = true
        
        toolbarHeight = inputToolbar.preferredDefaultHeight
        
        inputToolbar.delegate = self
        inputToolbar.contentView.textView.placeHolder = "New Message"
        inputToolbar.contentView.textView.delegate = self
        inputToolbar.removeFromSuperview()
        
        
        additionalContentInsets = .zero
        updateMessagesViewInsets()
        
        
    }
    
    
}


// MARK: - Presentor

extension CKMessagesViewController {
    
    
    fileprivate func hasPresentor(of message: CKMessageData) -> Bool {
        return registeredPresentors[String(describing: type(of:message))] != nil
    }
    
    fileprivate func isProcessable(of message: CKMessageData) -> Bool {
        var isProcessable = false
        
        switch message {
        case is CKMessage:
            isProcessable = true
        default:
            break
        }
        
        return isProcessable
        
    }
    
    fileprivate func presentor(of message: CKMessageData, at indexPath: IndexPath) -> CKMessagePresenting? {
        
        let MessageType = String(describing: type(of:message))
        guard let PresentorType = registeredPresentors[MessageType] else {
            return nil
        }
        
        // If pretchPresentors has presentor for indexPath then just use it
        
        if let presentor = prefetchedPresentors[indexPath] {
            usingPresentors[indexPath] = presentor
            prefetchedPresentors.removeValue(forKey: indexPath)
            return presentor
        }
        
        
        if var presentor = unusedPresentors[MessageType]?.first {
            unusedPresentors[MessageType]?.removeFirst()
            usingPresentors[indexPath] = presentor
            presentor.message = message
            return presentor
        }
        
        var presentor = PresentorType.presentor()
        presentor.message = message
        usingPresentors[indexPath] = presentor
        return presentor
        
    }
    
    fileprivate func prefetchPresentor(of message: CKMessageData, at indexPath: IndexPath) {
        
        guard prefetchedPresentors[indexPath] == nil else {
            return
        }
        
        let MessageType = String(describing: type(of:message))
        guard let PresentorType = registeredPresentors[MessageType] else {
            return
        }
        
        if var presentor = unusedPresentors[MessageType]?.first {
            unusedPresentors[MessageType]?.removeFirst()
            presentor.message = message
            prefetchedPresentors[indexPath] = presentor
        } else {
            var presentor = PresentorType.presentor()
            presentor.message = message
            prefetchedPresentors[indexPath] = presentor
        }
        
    }
    
    
    fileprivate func recyclePresentor(at indexPath: IndexPath) {
        
        if let presentor = usingPresentors[indexPath] {
            usingPresentors.removeValue(forKey: indexPath)
            
            let MessageType = String(describing: presentor.messageType)
            if unusedPresentors[MessageType] == nil {
                unusedPresentors[MessageType] = []
            }
            
            unusedPresentors[MessageType]!.append(presentor)
            
            presentor.messageView.removeFromSuperview()
        }
    }
}


// MARK: - Rotation
extension CKMessagesViewController {
    
    open override var shouldAutorotate: Bool {
        return true
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .allButUpsideDown
            
        default:
            return .all
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resetLayoutAndCaches()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        resetLayoutAndCaches()
    }
    
    
    private func resetLayoutAndCaches() {
        let context = CKMessagesViewLayoutInvalidationContext.context()
        context.invalidateLayoutMessagesCache = true
        messagesView.collectionViewLayout.invalidateLayout(with: context)
    }
}

// MARK: - Input

extension CKMessagesViewController {
    
    open override var canBecomeFirstResponder: Bool {
        return true
    }
    
    open override var inputAccessoryView: UIView? {
        return self.inputToolbar
    }
    
}

// MARK: - Scrolling & Insets

extension CKMessagesViewController {
    
    fileprivate func updateMessagesViewInsets(with keyboradFrame: CGRect = .zero) {
        
        var top = additionalContentInsets.top
        var bottom = additionalContentInsets.bottom + keyboradFrame.height
        if !automaticallyAdjustsScrollViewInsets {
            top += topLayoutGuide.length
            bottom += bottomLayoutGuide.length
        }
        
        
        
        let insets = UIEdgeInsets(top: top,
                                  left: additionalContentInsets.left,
                                  bottom: bottom,
                                  right: additionalContentInsets.right)
        
        self.messagesView.contentInset = insets
        self.messagesView.scrollIndicatorInsets = insets
    }
    
    
    public func scrollToBottom(animated: Bool) {
        let numberOfItems = messagesView.numberOfItems(inSection: 0)
        guard messagesView.numberOfSections == 1 && numberOfItems >= 1 else {
            return
        }
        
        let indexPath = IndexPath(item: numberOfItems - 1, section: 0)
        scroll(to: indexPath, animated: animated)
        
    }
    
    public func scroll(to indexPath: IndexPath, animated: Bool) {
        if messagesView.numberOfSections <= indexPath.section {
            return
        }
        
        let numberOfItems = messagesView.numberOfItems(inSection: 0)
        if numberOfItems == 0 {
            return
        }
        
        let contentHeight = messagesView.messagesViewLayout.collectionViewContentSize.height
        
        if contentHeight < messagesView.bounds.height {
            messagesView.scrollRectToVisible(CGRect(x: 0.0, y: contentHeight - 1.0, width: 1.0, height: 1.0), animated: animated)
            return
        }
        
        let item = max(min(indexPath.item, numberOfItems - 1), 0)
        let indexPath = IndexPath(item: item, section: 0)
        let size = messagesView.messagesViewLayout.sizeForItem(at: indexPath)
        let heightForVisibleMessage = messagesView.bounds.height
            - messagesView.contentInset.top
            - messagesView.contentInset.bottom
            - inputToolbar.bounds.height
        
        let scrollPosition: UICollectionViewScrollPosition = size.height > heightForVisibleMessage ? .bottom : .top
        
        messagesView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
        
    }
}

// MARK: - Notification

extension CKMessagesViewController {
    
    fileprivate func registerObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillChangeFrame(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivePreferredContentSizeChanged(_:)), name: Notification.Name.UIContentSizeCategoryDidChange, object: nil)
        
    }
    
    fileprivate func unregisterObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc private func didReceiveKeyboardWillChangeFrame(_ notification: Notification) {
        
        if let userInfo = notification.userInfo,
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double 
        {
        
            
            guard !keyboardEndFrame.isNull else {
                return
            }
            
            
            let animationOption = UIViewAnimationOptions(rawValue: UInt(animationCurve << 16))

            UIView.animate(withDuration: animationDuration,
                           delay: 0.0,
                           options: [animationOption],
                           animations:
                {
                    self.updateMessagesViewInsets(with: keyboardEndFrame)

                    
                }, completion: { _ in })
        }
        
    }
    
    

    
    @objc private func didReceivePreferredContentSizeChanged(_ notification: Notification) {
        messagesView.messagesViewLayout.invalidateLayout()
        messagesView.setNeedsLayout()
    }
    
    
}

// MARK: - UICollectionView

extension CKMessagesViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        var cellForItem: UICollectionViewCell!
        
        if let messagesView = collectionView as? CKMessagesView,
            let message = messagesView.messenger?.messageForItem(at: indexPath, of: messagesView) {
            
            var messageCell: CKMessageDataViewCell!
            
            
            if hasPresentor(of: message) {
                let cell: CKMessageDataViewCell = collectionView.dequeueReusable(at: indexPath)
                
                if #available(iOS 10, *) {
                    
                    /**
                     * For some unknown reason, on iOS 10, the hostedView sometime would be added to wrong indexPath cell
                     * which makes some cells are empty.
                     * So on iOS 10, at least, for now, moving attaching hostedView process to @collectionView(_:willDisplay:forItemAt:) delegate could solve the issue
                     */
                    prefetchPresentor(of: message, at: indexPath)
                    
                } else {
                    if let presentor = presentor(of: message, at: indexPath) {
                        cell.attach(hostedView: presentor.messageView)
                    }
                }
                
                messageCell = cell
                
            } else {
                
                // For all unregistered / unknown message type, handle as text message, which is the basic case of messages view
                
                let cell: CKMessageViewCell = collectionView.dequeueReusable(at: indexPath)
                cell.textView.text = message.text
                cell.textView.dataDetectorTypes = .all
                                
                messageCell = cell
            }
            
            
            var needsAvatar: Bool = true
            let isOutgoing = self.isOutgoing(message: message)
            if isOutgoing {
                messageCell.direction = .outgoing
                if messagesView.messagesViewLayout.outgoingAvatarSize == .zero {
                    needsAvatar = false
                }
                
            } else {
                messageCell.direction = .incoming
                if messagesView.messagesViewLayout.incomingAvatarSize == .zero {
                    needsAvatar = false
                }
            }
            
            
            var avatarImageData: CKMessagesAvatarImageData?
            
            if needsAvatar {
                avatarImageData = messagesView.decorator?.messagesView(messagesView, layout: messagesView.messagesViewLayout, avatarAt: indexPath)
                messageCell.avatarImageView.image = avatarImageData?.avatar
                messageCell.avatarImageView.highlightedImage = avatarImageData?.highlighted                
            }
            
            let bubbleImageData = messagesView.decorator?.messagesView(messagesView, layout: messagesView.messagesViewLayout, messageBubbleAt: indexPath)
            messageCell.messageBubbleImageView.image = bubbleImageData?.image
            messageCell.messageBubbleImageView.highlightedImage = bubbleImageData?.highlightedImage
            
            if let attributedText = messagesView.decorator?.messagesView(messagesView, layout: messagesView.messagesViewLayout, attributedTextForTopLabelAt: indexPath) {
                messageCell.topLabel.attributedText = attributedText
            } else if let text = messagesView.decorator?.messagesView(messagesView, layout: messagesView.messagesViewLayout, textForTopLabelAt: indexPath) {
                messageCell.topLabel.text = text
            }
            
            if let attributedText = messagesView.decorator?.messagesView(messagesView, layout: messagesView.messagesViewLayout, attributedTextForMessageTopLabelAt: indexPath) {
                messageCell.messageTopLabel.attributedText = attributedText
            } else if let text = messagesView.decorator?.messagesView(messagesView, layout: messagesView.messagesViewLayout, textForMessageTopLabelAt: indexPath) {
                
                var messageTopLabelInset: CGFloat = 15
                let textInsets = messageCell.messageTopLabel.textInsets
                if isOutgoing {
                    if messagesView.messagesViewLayout.outgoingAvatarSize != .zero {
                        messageTopLabelInset += messagesView.messagesViewLayout.outgoingAvatarSize.width
                    }
                    messageCell.messageTopLabel.textAlignment = .right
                    messageCell.messageTopLabel.textInsets = UIEdgeInsets(top: textInsets.top, left: 0, bottom: textInsets.bottom, right: messageTopLabelInset)
                    
                } else {
                    
                    if messagesView.messagesViewLayout.incomingAvatarSize != .zero {
                        messageTopLabelInset += messagesView.messagesViewLayout.incomingAvatarSize.width
                    }
                    
                    messageCell.messageTopLabel.textAlignment = .left
                    messageCell.messageTopLabel.textInsets = UIEdgeInsets(top: textInsets.top, left: messageTopLabelInset, bottom: textInsets.bottom, right: 0)
                }
                messageCell.messageTopLabel.text = text
            }
            
            
            
            if let attributedText = messagesView.decorator?.messagesView(messagesView, layout: messagesView.messagesViewLayout, attributedTextForBottomLabelAt: indexPath) {
                messageCell.bottomLabel.attributedText = attributedText
            } else if let text = messagesView.decorator?.messagesView(messagesView, layout: messagesView.messagesViewLayout, textForBottomLabelAt: indexPath) {
                messageCell.bottomLabel.text = text
                
                if  isOutgoing {
                    messageCell.bottomLabel.textAlignment = .right
                } else {
                    messageCell.bottomLabel.textAlignment = .left
                }
            }
                        
            cellForItem = messageCell
                        
        }
        
        assert(cellForItem != nil)
        
        cellForItem.layer.rasterizationScale = UIScreen.main.scale
        cellForItem.layer.shouldRasterize = true
        
        return cellForItem
        
        
        
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return messagesView.messagesViewLayout.sizeForItem(at: indexPath)
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        
        if let messagesView = collectionView as? CKMessagesView,
            let message = messagesView.messenger?.messageForItem(at: indexPath, of: messagesView) {
            
            if #available(iOS 10, *) {
                
                /**
                 * For some unknown reason, on iOS 10, the hostedView sometime would be added to wrong indexPath cell
                 * which makes some cells are empty.
                 * So on iOS 10, at least, for now, process attaching hostedView in willDisplay could solve the issue
                 */
                
                if let cell = cell as? CKMessageDataViewCell,
                    let presentor = presentor(of: message, at: indexPath) {
                    cell.attach(hostedView: presentor.messageView)
                    presentor.renderPresenting(with: message)
                }
            }
        }
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        recyclePresentor(at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionFooter:
            
            let indicator: CKMessagesIndicatorFooterView = collectionView.dequeueReusable(forSupplementaryView: UICollectionElementKindSectionFooter, at: indexPath)
            return indicator
            
        default:
            fatalError()
        }
        
    }
        
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return isShowingIndicator ? CGSize(width: messagesView.messagesViewLayout.itemWidth, height: 30) : .zero
    }
    
    fileprivate func isOutgoing(message: CKMessageData) -> Bool {
        return message.senderId == messagesView.messenger?.senderId
    }
}

@available(iOS 10, *)
extension CKMessagesViewController: UICollectionViewDataSourcePrefetching {
    
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
        guard let messagesView = collectionView as? CKMessagesView else {
            return
        }
        
        indexPaths.forEach { indexPath in
            if let message = messagesView.messenger?.messageForItem(at: indexPath, of: messagesView) {
                prefetchPresentor(of: message, at: indexPath)
            }
        }
        
        
    }
}

// MARK: - Input Toolbar Delegate
extension CKMessagesViewController: CKMessagesInputToolbarDelegate {
    
    public func toolbar(_ toolbar: CKMessagesInputToolbar, didClickLeftBarButton sender: UIButton) {
        
        switch toolbar.sendButtonPosition {
        case .left:
            didClickSendButton(sender, messageText: currentlyComposedMessageText())
        case .right:
            didClickAccessoryButton(sender)
        }
        
    }
    
    public func toolbar(_ toolbar: CKMessagesInputToolbar, didClickRightBarButton sender: UIButton) {
        
        switch toolbar.sendButtonPosition {
        case .left:
            didClickAccessoryButton(sender)
        case .right:
            didClickSendButton(sender, messageText: currentlyComposedMessageText())
            
        }
    }
    
    fileprivate func currentlyComposedMessageText() -> String {
        
        let textView = inputToolbar.contentView.textView!
        textView.inputDelegate?.selectionWillChange(textView)
        textView.inputDelegate?.selectionDidChange(textView)
        
        return textView.text.trimmingCharacters(in: .whitespaces)
    }
    
    open func didClickSendButton(_ button: UIButton, messageText: String) {
        
    }
    
    open func didClickAccessoryButton(_ button: UIButton) {
        
    }
}

// MARK: - Receive & Send Message
extension CKMessagesViewController {
    
    public func finishSendingMessage(animated: Bool = true) {
        let textView = inputToolbar.contentView.textView!
        textView.text = nil
        textView.undoManager?.removeAllActions()
        
        NotificationCenter.default.post(name: Notification.Name.UITextViewTextDidChange, object: textView)
        messagesView.messagesViewLayout.invalidateLayout(with: CKMessagesViewLayoutInvalidationContext.context())
        messagesView.reloadData()
        
        if automaticallyScrollsToMostRecentMessage {
            scrollToBottom(animated: animated)
        }
        
    }
    
    public func finishReceivingMessage(animated: Bool = true) {
        
        
        
        messagesView.messagesViewLayout.invalidateLayout(with: CKMessagesViewLayoutInvalidationContext.context())
        messagesView.reloadData()
        
        if automaticallyScrollsToMostRecentMessage {
            scrollToBottom(animated: animated)
        }
    }
    
}

// MARK: - TextView Delegate

extension CKMessagesViewController: UITextViewDelegate {
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        
        guard textView == inputToolbar.contentView.textView else {
            return
        }
        
        textView.becomeFirstResponder()
        
        if automaticallyScrollsToMostRecentMessage {
            scrollToBottom(animated: true)
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        
        guard textView == inputToolbar.contentView.textView else {
            return
        }
        
        textView.resignFirstResponder()
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        
        guard textView == inputToolbar.contentView.textView else {
            return
        }
        
        
    }
}

// MARK: - Debugging
extension CKMessagesViewController {
    fileprivate func debuggingPresentors(place: StaticString = #function) {
        print("===> \(place) usingPresentors: \(usingPresentors)")
        print("===> \(place) unusedPresentors: \(unusedPresentors)")
        print("===> \(place) pretchedPresentors: \(prefetchedPresentors)")
        print("")
        print("")
    }
}


