//
//  ViewController.swift
//  Example
//
//  Created by John DeLong on 5/11/16.
//  Copyright © 2016 delong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!

    let maxHeaderHeight: CGFloat = 88;
    let minHeaderHeight: CGFloat = 44;

    var previousScrollOffset: CGFloat = 0;

    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.headerHeightConstraint.constant = self.maxHeaderHeight
//        updateHeader()
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 40
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel!.text = "Cell \(indexPath.row)"
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollView.contentOffset.y", scrollView.contentOffset.y)
        //scrollView.contentOffset.y是指cell隱藏進header開始>0
        
        //最上或最下cells(不含header)都會彈跳
        //tableView往上滚动, contentOffset.y为正  http://www.jianshu.com/p/7c67f248d89f
        let scrollDiff = scrollView.contentOffset.y - self.previousScrollOffset  //原本是0
        
        let absoluteTop: CGFloat = 0;
        //scrollView.contentSize.height 1760.0 //所有cell加起來區
        //scrollView.frame.size.height 628.0  //手機上的可視cell區+header
        let absoluteBottom: CGFloat = scrollView.contentSize.height - scrollView.frame.size.height
        
        //滑到最下或最上的彈跳功能，會使下面兩個判斷在該情況錯誤地變成true
        let isScrollingDown = scrollDiff > 0 && scrollView.contentOffset.y > absoluteTop //判斷往下
        let isScrollingUp = scrollDiff < 0 && scrollView.contentOffset.y < absoluteBottom
        
        if canAnimateHeader(scrollView) {
            var newHeight = self.headerHeightConstraint.constant  //原本是張開的
            if isScrollingDown {  //一直減少，直到minHeaderHeight
                newHeight = max(self.minHeaderHeight, self.headerHeightConstraint.constant - abs(scrollDiff))
            } else if isScrollingUp {
                newHeight = min(self.maxHeaderHeight, self.headerHeightConstraint.constant + abs(scrollDiff))
            } //  Our header now grows and shrinks as the user scrolls - neat!
            
            if newHeight != self.headerHeightConstraint.constant {
                //把headerHeightConstraint.constantnewheight設為newHeight
                self.headerHeightConstraint.constant = newHeight
                self.updateHeader()
                self.setScrollPosition(self.previousScrollOffset)  //當header正在展開或縮減的時候，contentoffeset update到
                //ex. header向上縮減時持續update(抑制) self.tableView.contentOffset = y: 0.0
                //ex. 向下展開的時候持續
            }
            
            self.previousScrollOffset = scrollView.contentOffset.y
        }
        
    }
//However because there is not a scrollViewDidStop() method, we will use a combination of two UIScrollView delegate methods to determine when scrolling has stopped.
    
    //這個只有在微小運動到正要停止的瞬間才會被call
    //lets us know 何時 the scroll view has stopped scrolling after a “fling”
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrollViewDidStopScrolling()
    }

    //這個在用戶移開手指時會被call
    //如果只有這個(不管有沒有decelerate)：快速下拉又上移一點(有touch up)(被手強制停止)，會卡在中間。原因是? 下拉反往上touch up瞬間還有一點往上的decelerate造成header往上animate一點點
    //lets us know 何時 the scroll view has stopped scrolling after the user has removed their finger
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //The decelerate argument lets us know the the user “flung” the content with their finger
        //(in which case the scrollViewDidEndDecelerating() would eventually get called) 
        //or if the user brought the content to a stop and then removed their finger.
        
        //true if the scrolling movement will continue, but decelerate, after a touch-up gesture during a dragging operation
        if !decelerate {  //有這個不會跟scrollViewDidEndDecelerating打架？  If the value is false, scrolling stops immediately upon touch-up.
            self.scrollViewDidStopScrolling()
        }
    }

    func scrollViewDidStopScrolling() {
        let range = self.maxHeaderHeight - self.minHeaderHeight
        let midPoint = self.minHeaderHeight + (range / 2)

        if self.headerHeightConstraint.constant > midPoint {
            self.expandHeader()
        } else {
            self.collapseHeader()
        }
    }

    func canAnimateHeader(_ scrollView: UIScrollView) -> Bool {
        // Calculate the size of the scrollView when header is collapsed
        let scrollViewMaxHeight = scrollView.frame.height + self.headerHeightConstraint.constant - minHeaderHeight

        // Make sure that when header is collapsed, there is still room to scroll
        return scrollView.contentSize.height > scrollViewMaxHeight
    }

    func collapseHeader() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: {
            self.headerHeightConstraint.constant = self.minHeaderHeight
            self.updateHeader()
            self.view.layoutIfNeeded()
        })
    }

    func expandHeader() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: {
            self.headerHeightConstraint.constant = self.maxHeaderHeight
            self.updateHeader()
            self.view.layoutIfNeeded()
        })
    }

    func setScrollPosition(_ position: CGFloat) {
        print("position", position)
        self.tableView.contentOffset = CGPoint(x: self.tableView.contentOffset.x, y: position)
    }

    func updateHeader() {
        let range = self.maxHeaderHeight - self.minHeaderHeight
        let openAmount = self.headerHeightConstraint.constant - self.minHeaderHeight
        let percentage = openAmount / range

        self.titleTopConstraint.constant = -openAmount + 10
        self.logoImageView.alpha = percentage
    }
}
