-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Sep 26, 2025 at 10:44 PM
-- Server version: 8.3.0
-- PHP Version: 8.2.18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `my_favorite_artists`
--

-- --------------------------------------------------------

--
-- Table structure for table `album`
--

DROP TABLE IF EXISTS `album`;
CREATE TABLE IF NOT EXISTS `album` (
  `AlbumID` int NOT NULL AUTO_INCREMENT,
  `ArtistID` int NOT NULL,
  `GenreID` int NOT NULL,
  `AlbumDescription` varchar(300) NOT NULL,
  `AlbumRating` int NOT NULL,
  `AlbumName` varchar(200) NOT NULL,
  PRIMARY KEY (`AlbumID`),
  KEY `ArtistID` (`ArtistID`),
  KEY `GenreID` (`GenreID`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `album`
--

INSERT INTO `album` (`AlbumID`, `ArtistID`, `GenreID`, `AlbumDescription`, `AlbumRating`, `AlbumName`) VALUES
(1, 1, 1, 'This album was the last album made before Mac Miller\'s passing. It was about his mental health from when his career took off to the time he was making this album.', 8, 'Swimming'),
(4, 2, 1, 'By far my favorite album by kdot. Your mom wont play it in the car cause it got cursing in it.', 10, 'Good Kid Mad City'),
(5, 6, 5, 'Their best album. Love every track', 9, 'AM');

-- --------------------------------------------------------

--
-- Table structure for table `artists`
--

DROP TABLE IF EXISTS `artists`;
CREATE TABLE IF NOT EXISTS `artists` (
  `ArtistID` int NOT NULL AUTO_INCREMENT,
  `ArtistName` varchar(200) NOT NULL,
  PRIMARY KEY (`ArtistID`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `artists`
--

INSERT INTO `artists` (`ArtistID`, `ArtistName`) VALUES
(1, 'Mac Miller'),
(2, 'Kendrick Lamar'),
(3, 'SZA'),
(4, 'Jessie Reyez'),
(5, 'Post Malone'),
(6, 'Arctic Monkeys'),
(7, 'Taylor Swift');

-- --------------------------------------------------------

--
-- Table structure for table `genre`
--

DROP TABLE IF EXISTS `genre`;
CREATE TABLE IF NOT EXISTS `genre` (
  `GenreID` int NOT NULL AUTO_INCREMENT,
  `GenreName` varchar(200) NOT NULL,
  PRIMARY KEY (`GenreID`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `genre`
--

INSERT INTO `genre` (`GenreID`, `GenreName`) VALUES
(1, 'Rap'),
(4, 'Country'),
(5, 'Rock'),
(6, 'RnB'),
(7, 'Pop');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `album`
--
ALTER TABLE `album`
  ADD CONSTRAINT `album_ibfk_1` FOREIGN KEY (`ArtistID`) REFERENCES `artists` (`ArtistID`),
  ADD CONSTRAINT `album_ibfk_2` FOREIGN KEY (`GenreID`) REFERENCES `genre` (`GenreID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
