import 'dart:math';

import 'environment_mode.dart';

class CatalogItem {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final Map<String, List<String>> properties;
  final List<CatalogFact> facts;
  final List<String> settings;
  final List<String> interactions;
  final List<String> tags;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.properties,
    required this.facts,
    this.settings = const [],
    this.interactions = const [],
    this.tags = const [],
  });
}

class CatalogFact {
  final String id;
  final String text;
  const CatalogFact(this.id, this.text);
}

class ExploreSetting {
  final String id;
  final String name;
  final String emoji;
  final String subtitle;
  final List<String> itemIds;
  final List<String> challengeIds;
  final List<String> hiddenAreas;
  final EnvironmentMode mode;
  final bool isSpecialEvent;
  const ExploreSetting({
    required this.id,
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.itemIds,
    required this.challengeIds,
    this.hiddenAreas = const [],
    this.mode = EnvironmentMode.outdoor,
    this.isSpecialEvent = false,
  });
}

class ContentCatalog {
  ContentCatalog._();

  static const items = <CatalogItem>[
    CatalogItem(
      id: 'apple',
      name: 'Apple',
      emoji: '🍎',
      category: 'food',
      properties: {
        'colors': ['red', 'green', 'yellow'],
        'shapes': ['round'],
        'textures': ['smooth', 'crunchy'],
        'groups': ['plants', 'food'],
      },
      facts: [
        CatalogFact('apple_01', 'Apples grow on trees.'),
        CatalogFact('apple_02', 'Apples can be red, green, or yellow.'),
        CatalogFact('apple_03', 'Apples have a crunchy texture.'),
        CatalogFact('apple_04', 'Apple trees grow flowers before they grow apples.'),
      ],
      settings: ['kitchen', 'garden', 'dining'],
      interactions: ['drag', 'tap'],
      tags: ['fruit', 'round', 'red', 'green', 'yellow'],
    ),
    CatalogItem(
      id: 'banana',
      name: 'Banana',
      emoji: '🍌',
      category: 'food',
      properties: {
        'colors': ['yellow'],
        'shapes': ['curved'],
        'textures': ['smooth', 'soft'],
        'groups': ['plants', 'food'],
      },
      facts: [
        CatalogFact('banana_01', 'Bananas grow in bunches.'),
        CatalogFact('banana_02', 'A banana changes from green toward yellow as it ripens.'),
        CatalogFact('banana_03', 'Bananas have a soft inside.'),
        CatalogFact('banana_04', 'Banana plants have large leaves.'),
      ],
      settings: ['kitchen', 'dining'],
      interactions: ['drag', 'tap'],
      tags: ['fruit', 'yellow', 'curved'],
    ),
    CatalogItem(
      id: 'tomato',
      name: 'Tomato',
      emoji: '🍅',
      category: 'food',
      properties: {
        'colors': ['red', 'green', 'yellow'],
        'shapes': ['round'],
        'textures': ['smooth'],
        'groups': ['plants', 'food'],
      },
      facts: [
        CatalogFact('tomato_01', 'Tomatoes grow on plants.'),
        CatalogFact('tomato_02', 'Tomatoes can be red, yellow, or green.'),
        CatalogFact('tomato_03', 'A tomato is usually round or oval.'),
        CatalogFact('tomato_04', 'Tomato plants can grow flowers before fruit appears.'),
      ],
      settings: ['kitchen', 'garden', 'dining'],
      interactions: ['drag', 'tap'],
      tags: ['fruit', 'red', 'round'],
    ),
    CatalogItem(
      id: 'carrot',
      name: 'Carrot',
      emoji: '🥕',
      category: 'food',
      properties: {
        'colors': ['orange'],
        'shapes': ['long', 'pointed'],
        'textures': ['crunchy'],
        'groups': ['plants', 'food'],
      },
      facts: [
        CatalogFact('carrot_01', 'Carrots grow mostly underground.'),
        CatalogFact('carrot_02', 'The orange part is a root.'),
        CatalogFact('carrot_03', 'Carrot leaves grow above the soil.'),
        CatalogFact('carrot_04', 'Carrots can be crunchy when eaten raw.'),
      ],
      settings: ['kitchen', 'garden'],
      interactions: ['drag', 'tap'],
      tags: ['vegetable', 'orange', 'long'],
    ),
    CatalogItem(
      id: 'flower',
      name: 'Flower',
      emoji: '🌸',
      category: 'plant',
      properties: {
        'colors': ['pink', 'yellow', 'purple', 'white'],
        'shapes': ['round'],
        'textures': ['soft'],
        'groups': ['plants'],
      },
      facts: [
        CatalogFact('flower_01', 'Flowers can help plants make seeds.'),
        CatalogFact('flower_02', 'Many flowers attract insects.'),
        CatalogFact('flower_03', 'Flowers come in many shapes and colors.'),
        CatalogFact('flower_04', 'Some flowers open more in sunlight.'),
      ],
      settings: ['garden', 'park'],
      interactions: ['tap', 'water', 'swipe'],
      tags: ['plant', 'color', 'nature'],
    ),
    CatalogItem(
      id: 'tree',
      name: 'Tree',
      emoji: '🌳',
      category: 'plant',
      properties: {
        'colors': ['green', 'brown'],
        'shapes': ['tall'],
        'textures': ['rough'],
        'groups': ['plants'],
      },
      facts: [
        CatalogFact('tree_01', 'Trees have roots, trunks, branches, and leaves.'),
        CatalogFact('tree_02', 'Roots help hold a tree in the ground.'),
        CatalogFact('tree_03', 'Tree trunks support branches and leaves.'),
        CatalogFact('tree_04', 'Trees can provide homes for many animals.'),
      ],
      settings: ['garden', 'park', 'forest'],
      interactions: ['tap', 'drag', 'reveal'],
      tags: ['plant', 'tall', 'nature'],
    ),
    CatalogItem(
      id: 'leaf',
      name: 'Leaf',
      emoji: '🍃',
      category: 'plant',
      properties: {
        'colors': ['green', 'yellow', 'brown'],
        'shapes': ['oval', 'pointed'],
        'textures': ['smooth', 'veined'],
        'groups': ['plants'],
      },
      facts: [
        CatalogFact('leaf_01', 'Leaves help plants collect light.'),
        CatalogFact('leaf_02', 'Leaf veins carry water and nutrients.'),
        CatalogFact('leaf_03', 'Leaves can change color as seasons change.'),
        CatalogFact('leaf_04', 'Different plants can have very different leaf shapes.'),
      ],
      settings: ['garden', 'park', 'forest'],
      interactions: ['drag', 'swipe', 'reveal'],
      tags: ['plant', 'green', 'nature'],
    ),
    CatalogItem(
      id: 'butterfly',
      name: 'Butterfly',
      emoji: '🦋',
      category: 'animal',
      properties: {
        'colors': ['blue', 'orange', 'yellow', 'red'],
        'shapes': ['winged'],
        'textures': ['delicate'],
        'groups': ['animals'],
      },
      facts: [
        CatalogFact('butterfly_01', 'Butterflies have six legs.'),
        CatalogFact('butterfly_02', 'A butterfly starts life as a caterpillar.'),
        CatalogFact('butterfly_03', 'Butterfly wings are covered with tiny scales.'),
        CatalogFact('butterfly_04', 'Many butterflies visit flowers for nectar.'),
      ],
      settings: ['garden', 'park', 'forest'],
      interactions: ['tap', 'follow', 'reveal'],
      tags: ['animal', 'flying', 'colorful'],
    ),
    CatalogItem(
      id: 'bird',
      name: 'Bird',
      emoji: '🐦',
      category: 'animal',
      properties: {
        'colors': ['blue', 'brown', 'yellow', 'red'],
        'shapes': ['winged'],
        'textures': ['feathered'],
        'groups': ['animals'],
      },
      facts: [
        CatalogFact('bird_01', 'Birds have feathers.'),
        CatalogFact('bird_02', 'Many birds build nests for their eggs.'),
        CatalogFact('bird_03', 'Bird beaks come in many shapes.'),
        CatalogFact('bird_04', 'Many birds use their wings to fly.'),
      ],
      settings: ['garden', 'park', 'forest'],
      interactions: ['tap', 'follow', 'reveal'],
      tags: ['animal', 'flying'],
    ),
    CatalogItem(
      id: 'rock',
      name: 'Rock',
      emoji: '🪨',
      category: 'nature',
      properties: {
        'colors': ['gray', 'brown', 'white'],
        'shapes': ['irregular', 'round'],
        'textures': ['rough', 'smooth'],
        'groups': ['nature'],
      },
      facts: [
        CatalogFact('rock_01', 'Rocks can have many colors and textures.'),
        CatalogFact('rock_02', 'Some rocks are smooth because they have been worn over time.'),
        CatalogFact('rock_03', 'Rocks can be found in many places outdoors.'),
        CatalogFact('rock_04', 'Some rocks contain minerals.'),
      ],
      settings: ['garden', 'park', 'forest', 'beach'],
      interactions: ['tap', 'drag', 'reveal'],
      tags: ['nature', 'rough', 'gray'],
    ),
    CatalogItem(
      id: 'water',
      name: 'Water',
      emoji: '💧',
      category: 'nature',
      properties: {
        'colors': ['clear', 'blue'],
        'shapes': ['flowing'],
        'textures': ['wet'],
        'groups': ['nature'],
      },
      facts: [
        CatalogFact('water_01', 'Water can be a solid, liquid, or gas.'),
        CatalogFact('water_02', 'Plants need water to grow.'),
        CatalogFact('water_03', 'Rain is water that falls from clouds.'),
        CatalogFact('water_04', 'Water can change shape to fit its container.'),
      ],
      settings: ['garden', 'bathroom', 'kitchen', 'park'],
      interactions: ['drag', 'pour', 'tap'],
      tags: ['liquid', 'wet', 'blue'],
    ),
    CatalogItem(
      id: 'toothbrush',
      name: 'Toothbrush',
      emoji: '🪥',
      category: 'object',
      properties: {
        'colors': ['white', 'blue', 'pink', 'green'],
        'shapes': ['long'],
        'textures': ['bristly'],
        'groups': ['objects', 'bathroom'],
      },
      facts: [
        CatalogFact('toothbrush_01', 'A toothbrush has small bristles.'),
        CatalogFact('toothbrush_02', 'Toothbrushes are used to clean teeth.'),
        CatalogFact('toothbrush_03', 'A toothbrush has a handle to hold.'),
        CatalogFact('toothbrush_04', 'Brushing reaches different parts of your teeth.'),
      ],
      settings: ['bathroom'],
      interactions: ['drag', 'tap'],
      tags: ['bathroom', 'cleaning', 'long'],
    ),
    CatalogItem(
      id: 'soap',
      name: 'Soap',
      emoji: '🧼',
      category: 'object',
      properties: {
        'colors': ['white', 'pink', 'blue', 'green'],
        'shapes': ['oval', 'bar'],
        'textures': ['smooth', 'slippery'],
        'groups': ['objects', 'bathroom'],
      },
      facts: [
        CatalogFact('soap_01', 'Soap can help clean dirt from hands.'),
        CatalogFact('soap_02', 'Soap can make bubbles when mixed with water.'),
        CatalogFact('soap_03', 'Soap comes in many shapes and colors.'),
        CatalogFact('soap_04', 'Some soap is made as a solid bar.'),
      ],
      settings: ['bathroom', 'kitchen'],
      interactions: ['drag', 'tap', 'swipe'],
      tags: ['bathroom', 'cleaning', 'smooth'],
    ),
    CatalogItem(
      id: 'mirror',
      name: 'Mirror',
      emoji: '🪞',
      category: 'object',
      properties: {
        'colors': ['silver'],
        'shapes': ['rectangle', 'round'],
        'textures': ['smooth', 'shiny'],
        'groups': ['objects', 'bathroom'],
      },
      facts: [
        CatalogFact('mirror_01', 'A mirror can reflect light.'),
        CatalogFact('mirror_02', 'Smooth shiny surfaces can make clear reflections.'),
        CatalogFact('mirror_03', 'Mirrors come in many shapes.'),
        CatalogFact('mirror_04', 'A mirror can help us see what is behind us.'),
      ],
      settings: ['bathroom', 'bedroom', 'hall'],
      interactions: ['swipe', 'tap', 'reveal'],
      tags: ['reflection', 'shiny'],
    ),
    CatalogItem(
      id: 'book',
      name: 'Book',
      emoji: '📚',
      category: 'object',
      properties: {
        'colors': ['red', 'blue', 'green', 'yellow'],
        'shapes': ['rectangle'],
        'textures': ['smooth'],
        'groups': ['objects'],
      },
      facts: [
        CatalogFact('book_01', 'Books can tell stories or share information.'),
        CatalogFact('book_02', 'Pages are often made from paper.'),
        CatalogFact('book_03', 'Books come in many sizes and shapes.'),
        CatalogFact('book_04', 'Pictures in books can help us understand a story.'),
      ],
      settings: ['bedroom', 'hall', 'library'],
      interactions: ['drag', 'tap', 'reveal'],
      tags: ['rectangle', 'reading'],
    ),
    CatalogItem(
      id: 'lamp',
      name: 'Lamp',
      emoji: '💡',
      category: 'object',
      properties: {
        'colors': ['yellow', 'white'],
        'shapes': ['round', 'tall'],
        'textures': ['smooth'],
        'groups': ['objects'],
      },
      facts: [
        CatalogFact('lamp_01', 'A lamp changes electrical energy into light.'),
        CatalogFact('lamp_02', 'Lamps help us see when it is dark.'),
        CatalogFact('lamp_03', 'Lamp shades can come in many shapes.'),
        CatalogFact('lamp_04', 'Some lamps can be switched on and off.'),
      ],
      settings: ['bedroom', 'hall'],
      interactions: ['tap', 'drag'],
      tags: ['light', 'yellow'],
    ),
    CatalogItem(
      id: 'balloon',
      name: 'Balloon',
      emoji: '🎈',
      category: 'object',
      properties: {
        'colors': ['red', 'blue', 'yellow', 'pink'],
        'shapes': ['round', 'oval'],
        'textures': ['rubbery'],
        'groups': ['objects', 'party'],
      },
      facts: [
        CatalogFact('balloon_01', 'Balloons can float when filled with a lighter-than-air gas.'),
        CatalogFact('balloon_02', 'Balloons can come in many colors and shapes.'),
        CatalogFact('balloon_03', 'A balloon stretches as it is filled with air.'),
        CatalogFact('balloon_04', 'Balloons can move when air pushes against them.'),
      ],
      settings: ['party', 'hall'],
      interactions: ['tap', 'follow', 'drag'],
      tags: ['party', 'colorful', 'round'],
    ),
    CatalogItem(
      id: 'plate',
      name: 'Plate',
      emoji: '🍽️',
      category: 'object',
      properties: {
        'colors': ['white', 'blue', 'green'],
        'shapes': ['round'],
        'textures': ['smooth'],
        'groups': ['objects', 'kitchen'],
      },
      facts: [
        CatalogFact('plate_01', 'Plates hold food so it is easier to eat.'),
        CatalogFact('plate_02', 'Many plates are round.'),
        CatalogFact('plate_03', 'Plates can be made from ceramic, glass, or other materials.'),
        CatalogFact('plate_04', 'A plate has a broad surface for holding food.'),
      ],
      settings: ['kitchen', 'dining', 'party'],
      interactions: ['drag', 'sort'],
      tags: ['round', 'food', 'dining'],
    ),
    CatalogItem(
      id: 'cup',
      name: 'Cup',
      emoji: '🥤',
      category: 'object',
      properties: {
        'colors': ['red', 'blue', 'green', 'yellow'],
        'shapes': ['cylinder'],
        'textures': ['smooth'],
        'groups': ['objects', 'kitchen'],
      },
      facts: [
        CatalogFact('cup_01', 'A cup can hold a drink.'),
        CatalogFact('cup_02', 'Cups can be made from many materials.'),
        CatalogFact('cup_03', 'Some cups have handles.'),
        CatalogFact('cup_04', 'A cup has a hollow space inside for holding liquid.'),
      ],
      settings: ['kitchen', 'dining', 'party'],
      interactions: ['drag', 'sort', 'tap'],
      tags: ['drink', 'kitchen'],
    ),
    CatalogItem(
      id: 'toy',
      name: 'Toy',
      emoji: '🧸',
      category: 'object',
      properties: {
        'colors': ['red', 'blue', 'yellow', 'green'],
        'shapes': ['varied'],
        'textures': ['soft', 'smooth'],
        'groups': ['objects', 'toys'],
      },
      facts: [
        CatalogFact('toy_01', 'Toys can be used for pretend play and learning.'),
        CatalogFact('toy_02', 'Toys come in many shapes and materials.'),
        CatalogFact('toy_03', 'Sorting toys can help us compare their features.'),
        CatalogFact('toy_04', 'Some toys are designed to encourage movement.'),
      ],
      settings: ['bedroom', 'hall'],
      interactions: ['drag', 'sort', 'tap'],
      tags: ['toy', 'play'],
    ),
  ];

  static final itemsById = {for (final item in items) item.id: item};

  static const settings = <ExploreSetting>[
    // Core INDOOR worlds.
    ExploreSetting(
      id: 'bathroom',
      name: 'Bathroom',
      emoji: '🛁',
      subtitle: 'Water, bubbles, mirrors and getting-ready discoveries.',
      itemIds: ['water','toothbrush','soap','mirror'],
      challengeIds: ['bathroom_clean','bathroom_reveal'],
      hiddenAreas: ['mirror_message'],
      mode: EnvironmentMode.indoor,
    ),
    ExploreSetting(
      id: 'bedroom',
      name: 'Bedroom',
      emoji: '🛏️',
      subtitle: 'Toys, books, light and little bedtime mysteries.',
      itemIds: ['toy','book','lamp','mirror'],
      challengeIds: ['bedroom_sort','bedroom_shadow'],
      hiddenAreas: ['under_bed'],
      mode: EnvironmentMode.indoor,
    ),
    ExploreSetting(
      id: 'hall',
      name: 'Hall',
      emoji: '🛋️',
      subtitle: 'Everyday objects, light, movement and things we pass by.',
      itemIds: ['lamp','mirror','book','toy','balloon'],
      challengeIds: ['hall_match','hall_shadow'],
      hiddenAreas: ['hidden_drawer'],
      mode: EnvironmentMode.indoor,
    ),
    ExploreSetting(
      id: 'kitchen',
      name: 'Kitchen',
      emoji: '🍳',
      subtitle: 'Food, water, containers and everyday kitchen helpers.',
      itemIds: ['apple','banana','tomato','carrot','water','cup','plate'],
      challengeIds: ['kitchen_sort','kitchen_match'],
      hiddenAreas: ['recipe_corner'],
      mode: EnvironmentMode.indoor,
    ),
    ExploreSetting(
      id: 'dining',
      name: 'Dining Time',
      emoji: '🍽️',
      subtitle: 'A table full of objects, food and tiny sorting puzzles.',
      itemIds: ['apple','banana','tomato','plate','cup'],
      challengeIds: ['dining_table','dining_sort'],
      hiddenAreas: ['table_surprise'],
      mode: EnvironmentMode.indoor,
    ),
    ExploreSetting(
      id: 'library',
      name: 'Library',
      emoji: '📚',
      subtitle: 'Books, shapes, stories and a quiet mystery shelf.',
      itemIds: ['book','lamp'],
      challengeIds: ['library_sort','library_sequence'],
      hiddenAreas: ['secret_shelf'],
      mode: EnvironmentMode.indoor,
    ),
    ExploreSetting(
      id: 'shop',
      name: 'Grocery Shop',
      emoji: '🛒',
      subtitle: 'Find, sort and discover everyday foods and objects.',
      itemIds: ['apple','banana','tomato','carrot','cup','plate'],
      challengeIds: ['shop_sort','shop_match'],
      hiddenAreas: ['special_shelf'],
      mode: EnvironmentMode.indoor,
    ),

    // Core OUTDOOR worlds.
    ExploreSetting(
      id: 'garden',
      name: 'Garden',
      emoji: '🌳',
      subtitle: 'Flowers, leaves, tiny visitors and hidden corners.',
      itemIds: ['flower','tree','leaf','butterfly','bird','rock','water','apple'],
      challengeIds: ['garden_nest','garden_sort'],
      hiddenAreas: ['secret_garden'],
      mode: EnvironmentMode.outdoor,
    ),
    ExploreSetting(
      id: 'park',
      name: 'Park',
      emoji: '🛝',
      subtitle: 'Open-air discoveries with plants, rocks and animals.',
      itemIds: ['tree','flower','leaf','butterfly','bird','rock','water'],
      challengeIds: ['park_nature','park_match'],
      hiddenAreas: ['quiet_grove'],
      mode: EnvironmentMode.outdoor,
    ),
    ExploreSetting(
      id: 'forest',
      name: 'Forest',
      emoji: '🌲',
      subtitle: 'A magical nature trail with clues tucked between trees.',
      itemIds: ['tree','leaf','butterfly','bird','rock'],
      challengeIds: ['forest_trail','forest_sort'],
      hiddenAreas: ['hidden_hollow'],
      mode: EnvironmentMode.outdoor,
    ),
    ExploreSetting(
      id: 'beach',
      name: 'Beach',
      emoji: '🏖️',
      subtitle: 'Water, rocks, patterns and a changing shoreline.',
      itemIds: ['water','rock'],
      challengeIds: ['beach_sort','beach_reveal'],
      hiddenAreas: ['tide_pool'],
      mode: EnvironmentMode.outdoor,
    ),
    ExploreSetting(
      id: 'road',
      name: 'Road & Street',
      emoji: '🛣️',
      subtitle: 'Safe street-side observations, signs, shapes and sounds.',
      itemIds: ['rock','water','bird','tree'],
      challengeIds: ['road_shapes','road_sounds'],
      hiddenAreas: ['street_clue'],
      mode: EnvironmentMode.outdoor,
    ),

    // INDOOR SPECIAL EVENTS.
    ExploreSetting(
      id: 'birthday_party',
      name: 'Birthday Party',
      emoji: '🎂',
      subtitle: 'Balloons, gifts, food and a celebration mystery.',
      itemIds: ['balloon','plate','cup','apple','banana','toy'],
      challengeIds: ['party_sort','party_follow'],
      hiddenAreas: ['gift_corner'],
      mode: EnvironmentMode.indoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'holiday_stay',
      name: 'Holiday Stay',
      emoji: '🏨',
      subtitle: 'A cozy stay with rooms, luggage, breakfast and little discoveries.',
      itemIds: ['toy','book','lamp','mirror','cup','plate'],
      challengeIds: ['stay_sort','stay_search'],
      hiddenAreas: ['secret_room'],
      mode: EnvironmentMode.indoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'sleepover',
      name: 'Sleepover',
      emoji: '🌙',
      subtitle: 'Pillows, stories, quiet sounds and a bedtime mystery.',
      itemIds: ['toy','book','lamp','mirror'],
      challengeIds: ['sleepover_sequence','sleepover_search'],
      hiddenAreas: ['pillow_fort'],
      mode: EnvironmentMode.indoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'family_movie_night',
      name: 'Family Movie Night',
      emoji: '🍿',
      subtitle: 'Cozy snacks, seats, stories and a surprise after the lights dim.',
      itemIds: ['plate','cup','toy','book','lamp'],
      challengeIds: ['movie_sort','movie_sequence'],
      hiddenAreas: ['snack_surprise'],
      mode: EnvironmentMode.indoor,
      isSpecialEvent: true,
    ),

    // OUTDOOR SPECIAL EVENTS: Indian festivals + travel worlds.
    ExploreSetting(
      id: 'diwali',
      name: 'Diwali Celebration',
      emoji: '🪔',
      subtitle: 'Lights, colors, decorations and a celebration trail.',
      itemIds: ['flower','leaf','balloon','rock','water'],
      challengeIds: ['diwali_colors','diwali_lights'],
      hiddenAreas: ['glowing_corner'],
      mode: EnvironmentMode.outdoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'holi',
      name: 'Holi Celebration',
      emoji: '🎨',
      subtitle: 'Bright colors, music, movement and playful discovery.',
      itemIds: ['flower','water','balloon','leaf'],
      challengeIds: ['holi_colors','holi_sort'],
      hiddenAreas: ['color_trail'],
      mode: EnvironmentMode.outdoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'pongal',
      name: 'Pongal Celebration',
      emoji: '🌾',
      subtitle: 'Harvest colors, nature, food and a festive outdoor trail.',
      itemIds: ['carrot','apple','flower','leaf','water'],
      challengeIds: ['pongal_harvest','pongal_sort'],
      hiddenAreas: ['harvest_corner'],
      mode: EnvironmentMode.outdoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'onam',
      name: 'Onam Celebration',
      emoji: '🌼',
      subtitle: 'Flowers, patterns, nature and a festive discovery path.',
      itemIds: ['flower','leaf','apple','banana','water'],
      challengeIds: ['onam_pattern','onam_nature'],
      hiddenAreas: ['flower_path'],
      mode: EnvironmentMode.outdoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'train_journey',
      name: 'Train Journey',
      emoji: '🚆',
      subtitle: 'Watch the world go by and solve little travel clues.',
      itemIds: ['book','water','apple','banana','bird'],
      challengeIds: ['train_sequence','train_observe'],
      hiddenAreas: ['window_surprise'],
      mode: EnvironmentMode.outdoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'airplane_journey',
      name: 'Airplane Journey',
      emoji: '✈️',
      subtitle: 'Pack, travel, look outside and follow the sky-high clues.',
      itemIds: ['book','cup','water','apple'],
      challengeIds: ['plane_sequence','plane_search'],
      hiddenAreas: ['cloud_window'],
      mode: EnvironmentMode.outdoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'road_trip',
      name: 'Road Trip',
      emoji: '🚗',
      subtitle: 'A family journey with roadside sights, sounds and patterns.',
      itemIds: ['tree','bird','rock','water','apple'],
      challengeIds: ['roadtrip_search','roadtrip_sequence'],
      hiddenAreas: ['rest_stop'],
      mode: EnvironmentMode.outdoor,
      isSpecialEvent: true,
    ),
    ExploreSetting(
      id: 'boat_journey',
      name: 'Boat Journey',
      emoji: '⛵',
      subtitle: 'Water, wind, shorelines and gentle travel discoveries.',
      itemIds: ['water','rock','bird','leaf'],
      challengeIds: ['boat_observe','boat_sort'],
      hiddenAreas: ['shore_surprise'],
      mode: EnvironmentMode.outdoor,
      isSpecialEvent: true,
    ),
  ];

  static final settingsById = {for (final s in settings) s.id: s};

  static List<ExploreSetting> settingsForMode(EnvironmentMode mode) =>
      settings.where((s) => s.mode == mode && !s.isSpecialEvent).toList();

  static List<ExploreSetting> specialEventsForMode(EnvironmentMode mode) =>
      settings.where((s) => s.mode == mode && s.isSpecialEvent).toList();

  static CatalogItem? get(String id) => itemsById[id];

  static List<CatalogItem> forSetting(String settingId) {
    final setting = settingsById[settingId];
    if (setting == null) return [];
    return setting.itemIds.map((id) => itemsById[id]).whereType<CatalogItem>().toList();
  }
}

class FactMemory {
  final Map<String, List<String>> _seen = {};
  final Random _random;

  FactMemory({Random? random}) : _random = random ?? Random();

  String nextFact(CatalogItem item) {
    final seen = _seen.putIfAbsent(item.id, () => <String>[]);
    var available = item.facts.where((fact) => !seen.contains(fact.id)).toList();
    if (available.isEmpty) {
      seen.clear();
      available = List<CatalogFact>.from(item.facts);
    }
    available.shuffle(_random);
    final chosen = available.first;
    seen.add(chosen.id);
    return chosen.text;
  }

  Map<String, dynamic> toJson() => {
    for (final entry in _seen.entries) entry.key: List<String>.from(entry.value),
  };

  void load(Map<String, dynamic> json) {
    _seen.clear();
    for (final entry in json.entries) {
      final values = entry.value;
      if (values is List) _seen[entry.key] = values.whereType<String>().toList();
    }
  }
}
