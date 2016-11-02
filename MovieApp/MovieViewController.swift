//
//  MovieViewController.swift
//  MovieApp
//
//  Created by Lam Tran on 7/5/16.
//  Copyright © 2016 Tan Lam. All rights reserved.
//

import Foundation
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
    var posterUrl:URL?
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
        MBProgressHUD.showAdded(to: self.view, animated: true)
        loadData()
        
        refreshControl.addTarget(self, action: #selector(loadData), for: UIControlEvents.valueChanged)
        refreshControl1.addTarget(self, action: #selector(loadData), for: UIControlEvents.valueChanged)
        
        movieTable.insertSubview(refreshControl, at: 0)
        movieCollection.insertSubview(refreshControl1, at: 0)
        
        segment.setTitle("List", forSegmentAt: 0)
        segment.setTitle("Gird", forSegmentAt: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }

    func initLayout(){
        self.view.backgroundColor = UIColor.flatLime()
        movieTable.backgroundColor = UIColor.flatLime()
        movieCollection.backgroundColor = UIColor.flatLime()
        
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
        let apiKey = "657ef619d073734b47890f964e20dd10"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = URLRequest(
            url: url!,
            cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
            timeoutInterval: 10)
        
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: nil,
            delegateQueue: OperationQueue.main
        )
        
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (dataOrNil, response, error) in
            if let data = dataOrNil {
                self.networkError.isHidden = true
                if let responseDictionary = try! JSONSerialization.jsonObject(
                    with: data, options:[]) as? NSDictionary {
                    print("response: \(responseDictionary)")
                    self.movies = responseDictionary["results"] as! [NSDictionary]
                    self.movieTable.reloadData()
                    self.movieCollection.reloadData()
                    self.refreshControl.endRefreshing()
                    self.refreshControl1.endRefreshing()
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            } else {
                self.networkError.isHidden = false
                MBProgressHUD.hide(for: self.view, animated: true)
                self.refreshControl.endRefreshing()
                self.refreshControl1.endRefreshing()
            }
            
            
        })
        
        task.resume()
        
    }
    
    @IBAction func segmentAction(_ sender: UISegmentedControl) {
        if(sender.selectedSegmentIndex == 0){
            movieCollection.isHidden = true
            movieTable.isHidden = false
        } else {
            movieCollection.isHidden = false
            movieTable.isHidden = true
        }
    }
    
    
    //  MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
//        let cell = sender as! UITableViewCell
        let detailViewController = segue.destination as! DetailViewController
        
        if(movieCollection.isHidden){
            let indexPath = movieTable.indexPathForSelectedRow
            detailViewController.movie = movies[(indexPath?.row)!]
        } else{
            let ip = movieCollection.indexPathsForSelectedItems![0]
            detailViewController.movie = movies[(ip.row)]
        }
    }
}

extension MovieViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell") as! MovieTableViewCell!
        
        cell?.titleLabel?.text = movies[indexPath.row]["title"] as? String
        cell?.overviewLabel?.text = movies[indexPath.row]["overview"] as? String
        
        //  Fade in image
        
        if let imgPath = movies[indexPath.row]["poster_path"] as? String {
            
            let imageUrlRequest = URLRequest(url: URL(string: baseUrl + imgPath)!)
            cell?.posterImage.setImageWith(imageUrlRequest, placeholderImage: nil, success: { (imageUrlRequest, imageResponse, image) in
                if imageResponse != nil {
                    print("Image was NOT cached, fade in image")
                    cell?.posterImage.alpha = 0.0
                    cell?.posterImage.image = image
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        cell?.posterImage.alpha = 1.0
                    })
                } else {
                    print("Image was cached so just update the image")
                    cell?.posterImage.image = image
                }
            }) { (imageUrlRequest, imageResponse, image) in
                print("Image can't be load")
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //  Remove gray selection effect
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MovieViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return movies.count
    }
    
    @available(iOS 6.0, *)
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCollectionViewCell", for: indexPath) as! MovieCollectionViewCell
        
        //  Fade in image
        if let imgPath = movies[indexPath.row]["poster_path"] as? String {
            let imageUrlRequest = URLRequest(url: URL(string: baseUrl + imgPath)!)
            cell.posterImage.setImageWith(imageUrlRequest, placeholderImage: nil, success: { (imageUrlRequest, imageResponse, image) in
                if imageResponse != nil {
                    cell.posterImage.alpha = 0.0
                    cell.posterImage.image = image
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        cell.posterImage.alpha = 1.0
                    })
                } else {
                    cell.posterImage.image = image
                }
            }) { (imageUrlRequest, imageResponse, image) in
                print("Image can't be load")
            }
        }
        return cell
    }
}

extension MovieViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController){
//        let searchPredicate = NSPredicate(format: "SELF like %@", searchController.searchBar.text!)
        movies = movies.filter{($0["title"] as! String).contains(searchController.searchBar.text!)}
       
        movieTable.reloadData()
        movieCollection.reloadData()
        
    }
    
}

