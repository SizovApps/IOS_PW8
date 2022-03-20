//
//  ViewController.swift
//  visizovPW8
//
//  Created by user on 20.03.2022.
//

import UIKit

class MoviesViewController: UIViewController {
    
    private let tableView = UITableView()
    
    var movies: [Movie] = []
    
    private let apiKey = "8d7578926c53d771fc40561975e4ab50"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureUI()
        // Do any additional setup after loading the view.
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.loadMovies()
        }
    }
    
    private func configureUI() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.register(MoviewCell.self, forCellReuseIdentifier: MoviewCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.reloadData()
    }
    
    private func loadMovies() {
        guard let url = URL(string: "https://developers.themoviedb.org/3/discover/movie?api_key=\(apiKey)$language=ruRu") else {
            return assertionFailure("some problems wirh url")
        }
        let session = URLSession.shared.dataTask(with: URLRequest(url: url), completionHandler: {data, _, _ in
            guard
                let data = data,
                let dict = try? JSONSerialization.jsonObject(with: data, options: .json5Allowed) as? [String: Any],
                let results = dict["results"] as? [[String: Any]]
            else {return}
            let movies: [Movie] = results.map{ params in
                let title = params["title"] as! String
                let imagePath = params["poster_path"] as! String
                return Movie(title: title, posterPath: imagePath)
            }
            
            self.loadPostertForMovie(movies) { movies in
                self.movies = movies
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    
        })
        session.resume()
    }
    
    func loadPostertForMovie(_ movies: [Movie], completion: @escaping ([Movie]) -> Void) {
        let group = DispatchGroup()
        for movie in movies {
            group.enter()
            DispatchQueue.global(qos: .background).async {
                movie.loadPoster { _ in
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            completion(movies)
        }
    }
}

extension MoviesViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MoviewCell.identifier, for: indexPath) as! MoviewCell
        cell.configure(movie: movies[indexPath.row])
        return MoviewCell()
    }
}

class Movie {
    let title: String
    let posterPath: String?
    var poster: UIImage? = nil
    
    init(
        title: String,
        posterPath: String?
    ) {
        self.title = title
        self.posterPath = posterPath
    }
    
    func loadPoster(completion: @escaping (UIImage?) -> Void) {
        guard
            let posterPath = posterPath,
            let url = URL(string: "https://images.tmbd.org/t/p/original/\(posterPath)")
        else {
            return completion(nil)
        }
        
        let request = URLSession.shared.dataTask(with: URLRequest(url: url)) { [weak self] data, _, _ in
            guard
                let data = data,
                let image = UIImage(data: data) else {
                    return completion(nil)
                }
            self?.poster = image
            completion(image)
        }
        request.resume()
    }
    
}

class MoviewCell: UITableViewCell {
    static let identifier = "MovieCell"
    private let poster = UIImageView()
    private let title = UILabel()
    
    init() {
        super.init(style: .default, reuseIdentifier: Self.identifier)
        configureUI()
    }
    
    func configure(movie: Movie) {
        title.text = movie.title
        poster.image = movie.poster
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        poster.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(poster)
        addSubview(title)
        
        NSLayoutConstraint.activate([
            poster.topAnchor.constraint(equalTo: topAnchor),
            poster.leadingAnchor.constraint(equalTo: leadingAnchor),
            poster.trailingAnchor.constraint(equalTo: trailingAnchor),
            poster.heightAnchor.constraint(equalToConstant: 200),
            
            title.topAnchor.constraint(equalTo: poster.bottomAnchor, constant: 10),
            title.leadingAnchor.constraint(equalTo: leadingAnchor),
            title.trailingAnchor.constraint(equalTo: trailingAnchor),
            title.heightAnchor.constraint(equalToConstant: 20)
        ])
        title.textAlignment = .center
    }
}

