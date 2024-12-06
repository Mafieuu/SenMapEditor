import 'package:latlong2/latlong.dart';
import 'dart:math';
// Methode de merge des polygones base sur les enveloppe convexe
//Cette méthode fusionne plusieurs polygones en un seul en dédupliquant les points,
// en regroupant les points proches, puis en utilisant l'algorithme de l'enveloppe convexe pour créer un polygone nouveau.
// Elle connecte  des points pour former un seul polygone englobant toutes les zones couvertes par les polygones d'origine.
class PolygonMerger {
  // Calcul distance euclidiens
  static double _calculateDistance(LatLng point1, LatLng point2) {
    return sqrt(
        pow(point1.latitude - point2.latitude, 2) +
            pow(point1.longitude - point2.longitude, 2)
    );
  }

  // verifie si deux points sont proche a threshold pres
  static bool _arePointsClose(LatLng point1, LatLng point2,
      {double threshold = 1e-6})
  {
    return _calculateDistance(point1, point2) < threshold;
  }

  // merge des polygones
  static List<LatLng> mergePolygons(List<List<LatLng>> polygons) {
    if (polygons.isEmpty) return [];
    if (polygons.length == 1) return polygons.first;

    // Applatissement et regroupements des points proches
    Set<LatLng> uniquePoints = {};
    for (var polygon in polygons) {
      uniquePoints.addAll(polygon);
    }
// regrouper les points proches dans des clusters pointClusters
    Map<LatLng, List<LatLng>> pointClusters = {};
    for (var point in uniquePoints) {
      bool merged = false;
      for (var cluster in pointClusters.keys) {
        if (_arePointsClose(point, cluster)) {
          pointClusters[cluster]!.add(point);
          merged = true;
          break;
        }
      }
      if (!merged) {
        pointClusters[point] = [point];
      }
    }

    // Pour chaque cluster prendre un seul representant
    List<LatLng> mergedPoints = [];
    for (var point in uniquePoints) {
      var representative = pointClusters.keys.firstWhere(
              (k) => pointClusters[k]!.contains(point)
      );
      if (!mergedPoints.contains(representative)) {
        mergedPoints.add(representative);
      }
    }

    // trie des points  pour former un enveloppe convexe: l'algorithme de balayage de Gram
    return _convexAlgo(mergedPoints);
  }

  // algo de balayage de gramme pour trier les points afin de  formerer un polygone convexe
  // elle prend en input une liste de points pour   former une nouvelle liste qui sera enveloppe convexe
  // voir https://fr.wikipedia.org/wiki/Parcours_de_Graham#:~:text=En%20informatique%2C%20et%20en%20g%C3%A9om%C3%A9trie%20algorithmique%2C%20le%20parcours,n%29%20o%C3%B9%20n%20est%20le%20nombre%20de%20points.
  // pour les details technique de l'algorithme
  static List<LatLng> _convexAlgo(List<LatLng> points) {
    if (points.length <= 3) return points;

    // Trouve le point avec la latitude la plus basse (et le plus à gauche en cas d'égalité)
    LatLng bottomPoint = points.reduce((a, b) {
      if (a.latitude < b.latitude) return a;
      if (a.latitude > b.latitude) return b;
      return a.longitude < b.longitude ? a : b;
    });

    // Trie les points par angle polaire par rapport au point le plus bas
    points.sort((a, b) {
      double angleA = atan2(a.latitude - bottomPoint.latitude,
          a.longitude - bottomPoint.longitude);
      double angleB = atan2(b.latitude - bottomPoint.latitude,
          b.longitude - bottomPoint.longitude);
      return angleA.compareTo(angleB);
    });
    //enveloppe convexe le plus bas
    List<LatLng> hull = [bottomPoint];
    for (var point in points) {
      while (hull.length > 1 &&
          _crossProduct(hull[hull.length - 2], hull.last, point) <= 0) {
        hull.removeLast();
      }
      hull.add(point);
    }

    return hull;
  }

  // produit vectoriel pour determiner la direction du virage entre trois points
  static double _crossProduct(LatLng o, LatLng a, LatLng b) {
    return (a.longitude - o.longitude) * (b.latitude - o.latitude) -
        (a.latitude - o.latitude) * (b.longitude - o.longitude);
  }

}