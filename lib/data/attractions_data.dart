import 'package:latlong2/latlong.dart';
import '../models/attraction_model.dart';

final List<Attraction> attractions = [
  Attraction(
    name: "Acropolis Museum", 
    description: "The Acropolis is Athens’ most iconic ancient citadel, standing high above the city. It represents the peak of classical Greek architecture and history.", 
    imagePath: "assets/akropolimuseum.jpg", 
    location: const LatLng(37.9685, 23.7285), 
    ),
  
  Attraction(
    name: "Panathenaic Stadium",
    description: "The Panathenaic Stadium is the only stadium in the world built entirely of marble. It hosted the first modern Olympic Games in 1896.", 
    imagePath: "assets/stadium.jpg",
    location: const LatLng(37.9686, 23.7411),
  ),
  Attraction(
    name: "National Archaeological Museum", description: "The National Archaeological Museum houses the richest collection of ancient Greek artifacts. It showcases masterpieces from all periods of Greek antiquity.", 
    imagePath: "assets/nationalmuseum.jpg", 
    location: const LatLng(37.9890, 23.7315),
  ),
  Attraction(
    name: "National Gallery", 
    description: "The National Gallery of Athens showcases modern and contemporary Greek art. Its renovated building offers a bright, spacious environment for visitors.", 
    imagePath: "assets/nationalgallery.jpg", 
    location: const LatLng(37.9730, 23.7370),
  ),
  Attraction(
    name: "Mount Lycabettus",
    description: "Mount Lycabettus is a Cretaceous limestone hill in Athens. At 300 meters above sea level, its summit is the highest point in Athens.",
    imagePath: "assets/likavitos.jpg",
    location: const LatLng(37.9818, 23.7430),
  ),
  Attraction(
    name: "Plaka",
    description: "Plaka is the old historical neighborhood of Athens, clustered around the northern and eastern slopes of the Acropolis.",
    imagePath: "assets/plaka.jpg",
    location: const LatLng(37.9735, 23.7295),
  ),
];