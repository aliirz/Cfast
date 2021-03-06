//
//  FireBaseViewController.swift
//  Cfast
//
//  Created by Haroon on 27/02/2015.
//  Copyright (c) 2015 Cfast. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class FireBaseViewController: JSQMessagesViewController, UIActionSheetDelegate {
    
    
    var messages = [Message]()
    //var avatars = Dictionary<String, UIImage>()
    var avatars = [String: JSQMessagesAvatarImage]()
    var something = UIColor.jsq_messageBubbleLightGrayColor()
    var isQuery: Bool = false
    var isDoctor: Bool = false
    
    
    
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    
    var senderImageUrl: String!
    
    var senderActualName: String!
    
    var batchMessages = true
    
    var ref: Firebase!
    // *** STEP 1: STORE FIREBASE REFERENCES
    var messagesRef: Firebase!
    
    func setupFirebase() {
        // *** STEP 2: SETUP FIREBASE
        messagesRef = Firebase(url: "https://vivid-inferno-9712.firebaseio.com/messages")
        
        if !isQuery {
            // *** STEP 4: RECEIVE MESSAGES FROM FIREBASE
            messagesRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
                let text = snapshot.value["text"] as? String
                let sender = snapshot.value["sender"] as? String
                let imageUrl = snapshot.value["imageUrl"] as? String
                
                if let messageFilter = snapshot.value["senderName"] as? String {
                    if messageFilter == self.senderActualName || self.isDoctor {
                        if let testOptionalValue = text {
                            let message = Message(text: text, sender: sender, imageUrl: imageUrl)
                            self.messages.append(message)
                            self.finishReceivingMessage()
                        }
                    }
                }
            })
        }
    }
    
    func sendMessage(text: String!, sender: String!) {
        // *** STEP 3: ADD A MESSAGE TO FIREBASE
        messagesRef.childByAutoId().setValue([
            "text":text,
            "sender":senderDisplayName,
            "imageUrl":senderImageUrl,
            "senderName": senderActualName
            ])
    }
    
    func tempSendMessage(text: String!, sender: String!) {
        let message = Message(text: text, sender: sender, imageUrl: senderImageUrl)
        messages.append(message)
    }
    
    func setupAvatarImage(name: String, imageUrl: String?, incoming: Bool) {
        if imageUrl == nil ||  countElements(imageUrl!) == 0 {
            setupAvatarColor(name, incoming: incoming)
            return
        }
        
        let diameter = incoming ? UInt(collectionView.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView.collectionViewLayout.outgoingAvatarViewSize.width)
        
        let url = NSURL(string: imageUrl!)
        
        if let data = NSData(contentsOfURL: url!) {
            
            let image = UIImage(data: NSData(contentsOfURL: url!)!)
            let avatarImage = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: diameter)
            
            avatars[name] = avatarImage
        }
    }
    
    func setupAvatarColor(name: String, incoming: Bool) {
        let diameter = incoming ? UInt(collectionView.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView.collectionViewLayout.outgoingAvatarViewSize.width)
        
        let rgbValue = name.hash
        let r = CGFloat(Float((rgbValue & 0xFF0000) >> 16)/255.0)
        let g = CGFloat(Float((rgbValue & 0xFF00) >> 8)/255.0)
        let b = CGFloat(Float(rgbValue & 0xFF)/255.0)
        let color = UIColor(red: r, green: g, blue: b, alpha: 0.5)
        
        let nameLength = countElements(name)
        
        let initials : String? = name.substringToIndex(advance(senderDisplayName.startIndex, min(3, nameLength)))
        
        let userImage = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initials, backgroundColor: color, textColor: UIColor.blackColor(), font: UIFont.systemFontOfSize(CGFloat(13)), diameter: diameter)
        
        avatars[name] = userImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //inputToolbar.contentView.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        navigationController?.navigationBar.topItem?.title = "Home"
        
        senderDisplayName = (senderDisplayName != nil) ? senderDisplayName : "Anonymous"
        let profileImageUrl: NSString? = "https://pbs.twimg.com/profile_images/450268509319081985/Szabe27e.jpeg"
        if let urlString = profileImageUrl {
            setupAvatarImage(senderDisplayName, imageUrl: urlString, incoming: false)
            senderImageUrl = urlString
        } else {
            setupAvatarColor(senderDisplayName, incoming: false)
            senderImageUrl = ""
        }
        self.showLoadEarlierMessagesHeader = true
        
        let getDefaults = NSUserDefaults()
        senderActualName = getDefaults.objectForKey("userName") as String
        
        setupFirebase()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.springinessEnabled = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if ref != nil {
            ref.unauth()
        }
    }
    
    // ACTIONS
    
    func receivedMessagePressed(sender: UIBarButtonItem) {
        // Simulate reciving message
        showTypingIndicator = !showTypingIndicator
        scrollToBottomAnimated(true)
    }
    
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        sendMessage(text, sender: senderDisplayName)
        
        if isQuery{
            SweetAlert().showAlert("Sent", subTitle: "Your query has been submitted", style: .Success)
        }
        
        //finishSendingMessage()
        finishSendingMessageAnimated(true)
    }
    
    
    override func didPressAccessoryButton(sender: UIButton!) {
        var UIAction = UIActionSheet(title: "Media Messages", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Send Photo", "Send File", "Send Location")
        UIAction.showFromToolbar(self.inputToolbar)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        println("Action Sheet Gone!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        
        if message.sender() == senderDisplayName {
            return outgoingBubbleImageView
        }
        
        return incomingBubbleImageView
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        if let avatar = avatars[message.sender()] {
            return avatar
            
        }
        else {
            setupAvatarImage(message.sender(), imageUrl: message.imageUrl(), incoming: true)
            return avatars[message.sender()]
        }
        
        
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        if message.sender() == senderDisplayName {
            cell.textView.textColor = UIColor.blackColor()
        } else {
            cell.textView.textColor = UIColor.whiteColor()
        }
        
        let attributes : [NSObject:AnyObject] = [NSForegroundColorAttributeName:cell.textView.textColor, NSUnderlineStyleAttributeName: 1]
        cell.textView.linkTextAttributes = attributes
        
        //        cell.textView.linkTextAttributes = [NSForegroundColorAttributeName: cell.textView.textColor,
        //            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle]
        return cell
    }
    
    
    // View  usernames above bubbles
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item];
        
        // Sent by me, skip
        if message.sender() == senderDisplayName {
            return nil;
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.sender() == message.sender() {
                return nil;
            }
        }
        
        return NSAttributedString(string:message.sender())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        
        // Sent by me, skip
        if message.sender() == senderDisplayName {
            return CGFloat(0.0);
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.sender() == message.sender() {
                return CGFloat(0.0);
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    
    
}
