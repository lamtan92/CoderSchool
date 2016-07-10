//
//  MovieViewController.swift
//  MovieApp
//
//  Created by Lam Tran on 7/5/16.
//  Copyright © 2016 Tan Lam. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD
import ChameleonFramework

class MovieViewController: UIViewController {
  
    @IBOutlet weak var networkError: UILabel!
    @IBOutlet weak var movieTable: UITableView!
    @IBOutlet weak var movieCollection: UICollectionView!
    @IBOutlet weak var segment: UISegmentedControl!
    
    var movies = [NSDictionary]()
    var baseUrl = "http://image.tmdb.org/t/p/w342"
    var posterUrl:NSURL?
    var endpoint = ""
    
    let refreshControl = UIRefreshControl()
    let refreshControl1 = UIRefreshControl()
    var searchController : UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initLayout()
        movieTable.dataSource = self
        movieTable.delegate = self
        
        movieCollection.dataSource = self
        movieCollection.delegate = self
        
        //  Show progress
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadData()
        
        refreshControl.addTarget(self, action: #selector(loadData), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl1.addTarget(self, action: #selector(loadData), forControlEvents: UIControlEvents.ValueChanged)
        
        movieTable.insertSubview(refreshControl, atIndex: 0)
        movieCollection.insertSubview(refreshControl1, atIndex: 0)
        
        segment.setTitle("List", forSegmentAtIndex: 0)
        segment.setTitle("Gird", forSegmentAtIndex: 1)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.tabBarController?.tabBar.hidden = false
    }

    func initLayout(){
        self.view.backgroundColor = UIColor.flatLimeColor()
        movieTable.backgroundColor = UIColor.flatLimeColor()
        movieCollection.backgroundColor = UIColor.flatLimeColor()
        
        self.searchController = UISearchController(searchResultsController:  nil)
        
        self.searchController.searchResultsUpdater = self
        self.searchController.delegate = self
        self.searchController.searchBar.delegate = self
        
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.dimsBackgroundDuringPresentation = true
        
        self.navigationItem.titleView = searchController.searchBar
        
        self.definesPresentationContext = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
  
    //  MARK: -Load data
    func loadData(){
        
        //  Get data from movie API
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(
            URL: url!,
            cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval: 10)
        
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { (dataOrNil, response, error) in
                                                                        if let data = dataOrNil {
                                                                            self.networkError.hidden = true
                                                                            if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                                                                                data, options:[]) as? NSDictionary {
                                                                                print("response: \(responseDictionary)")
                                                                                self.movies = responseDictionary["results"] as! [NSDictionary]
                                                                                self.movieTable.reloadData()
                                                                                self.movieCollection.reloadData()
                                                                                self.refreshControl.endRefreshing()
                                                                                self.refreshControl1.endRefreshing()
                                                                                MBProgressHUD.hideHUDForView(self.view, animated: true)
                                                                            }
                                                                        } else {
                                                                            self.networkError.hidden = false
                                                                            MBProgressHUD.hideHUDForView(self.view, animated: true)
                                                                            self.refreshControl.endRefreshing()
                                                                            self.refreshControl1.endRefreshing()
                                                                        }
            
            
        })
        
        task.resume()

    }
    
    @IBAction func segmentAction(sender: UISegmentedControl) {
        if(sender.selectedSegmentIndex == 0){
            movieCollection.hidden = true
            movieTable.hidden = false
        } else {
            movieCollection.hidden = false
            movieTable.hidden = true
        }
    }
    
    
    //  MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
//        let cell = sender as! UITableViewCell
        let detailViewController = segue.destinationViewController as! DetailViewController
        
        if(movieCollection.hidden){
            let indexPath = movieTable.indexPathForSelectedRow
            detailViewController.movie = movies[(indexPath?.row)!]
        } else{
            let ip = movieCollection.indexPathsForSelectedItems()![0]
            detailViewController.movie = movies[(ip.row)]
        }
    }
}

extension MovieViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell") as! MovieTableViewCell!
        
        cell.titleLabel?.text = movies[indexPath.row]["title"] as? String
        cell.overviewLabel?.text = movies[indexPath.row]["overview"] as? String
        
        let imageUrlRequest = NSURLRequest(URL: NSURL(string: baseUrl + (movies[indexPath.row]["poster_path"] as? String)!)!)
//        posterUrl = NSURL(string: baseUrl + (movies[indexPath.row]["poster_path"] as? String)!)
//        cell.posterImage.setImageWithURL(posterUrl!)
        cell.posterImage.setImageWithURLRequest(imageUrlRequest, placeholderImage: nil, success: { (imageUrlRequest, imageResponse, image) in
            if imageResponse != nil {
                print("Image was NOT cached, fade in image")
                cell.posterImage.alpha = 0.0
                cell.posterImage.image = image
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    cell.posterImage.alpha = 1.0
                })
            } else {
                print("Image was cached so just update the image")
                cell.posterImage.image = image
            }
            }) { (imageUrlRequest, imageResponse, image) in
                print("Image can't be load")
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //  Remove gray selection effect
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

extension MovieViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return movies.count
        
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    @available(iOS 6.0, *)
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieCollectionViewCell", forIndexPath: indexPath) as! MovieCollectionViewCell

        posterUrl = NSURL(string: baseUrl + (movies[indexPath.row]["poster_path"] as? String)!)
        cell.posterImage.setImageWithURL(posterUrl!)
        
        return cell
    }
}

extension MovieViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController){
        
    }
    
}

