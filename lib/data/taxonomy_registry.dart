import 'package:flutter/material.dart';

import '../models/taxonomy.dart';

/// The four classification axes besides tool. Data, not enums, so the
/// library can grow a new niche or use case without a code change.
///
/// Icons are supplied here directly rather than by name: the name→icon map
/// used to live in the model layer, which meant a new category with a new
/// icon quietly required a model edit. Now everything a category needs is
/// in this file.

const List<Taxon> useCases = [
  // Creative / generative
  Taxon(
    id: 'avatar_creation',
    label: 'Avatar creation',
    icon: Icons.face_retouching_natural_outlined,
  ),
  Taxon(
    id: 'brand_design',
    label: 'Brand design',
    icon: Icons.palette_outlined,
  ),
  Taxon(
    id: 'motion_web_design',
    label: 'Motion web design',
    icon: Icons.animation_outlined,
  ),
  Taxon(
    id: 'product_photography',
    label: 'Product photography',
    icon: Icons.camera_alt_outlined,
  ),
  Taxon(
    id: 'social_media_video',
    label: 'Social media video',
    icon: Icons.movie_creation_outlined,
  ),
  Taxon(
    id: 'logo_brand_kit',
    label: 'Logo and brand kit',
    icon: Icons.auto_awesome_mosaic_outlined,
  ),

  // Business / document design
  Taxon(
    id: 'slide_deck_design',
    label: 'Slide deck design',
    icon: Icons.slideshow_outlined,
  ),
  Taxon(
    id: 'data_viz_dashboard',
    label: 'Dashboards and charts',
    icon: Icons.insert_chart_outlined,
  ),
  Taxon(
    id: 'pdf_document_design',
    label: 'PDF document design',
    icon: Icons.description_outlined,
  ),
  Taxon(
    id: 'resume_design',
    label: 'Resume and CV',
    icon: Icons.badge_outlined,
  ),
];

const List<Taxon> niches = [
  Taxon(id: 'fitness', label: 'Fitness'),
  Taxon(id: 'real_estate', label: 'Real estate'),
  Taxon(id: 'ecommerce', label: 'E-commerce'),
  Taxon(id: 'agency', label: 'Agency'),
  // Business-document work (decks, dashboards, proposals, resumes) lands in
  // different industries than the creative-tool prompts do.
  Taxon(id: 'saas', label: 'SaaS / tech'),
  Taxon(id: 'consulting', label: 'Consulting'),
  Taxon(id: 'finance', label: 'Finance'),
];

const List<Taxon> outputTypes = [
  Taxon(id: 'image', label: 'Image', icon: Icons.image_outlined),
  Taxon(id: 'video', label: 'Video', icon: Icons.movie_creation_outlined),
  Taxon(id: 'webpage', label: 'Webpage', icon: Icons.web_outlined),
  Taxon(id: 'brand_kit', label: 'Brand kit', icon: Icons.style_outlined),
  Taxon(
    id: 'presentation',
    label: 'Slide deck',
    icon: Icons.slideshow_outlined,
  ),
  Taxon(id: 'dashboard', label: 'Dashboard', icon: Icons.insert_chart_outlined),
  // Resumes, proposals and reports are all "a designed document", so they
  // share one output type and separate on use case instead.
  Taxon(id: 'document', label: 'Document', icon: Icons.description_outlined),
];

const List<Taxon> inputMethods = [
  Taxon(
    id: 'own_photo',
    label: 'From my own photo',
    icon: Icons.photo_camera_back_outlined,
  ),
  Taxon(id: 'from_scratch', label: 'From scratch', icon: Icons.edit_outlined),
  Taxon(
    id: 'from_template',
    label: 'From a template',
    icon: Icons.dashboard_customize_outlined,
  ),
  // Needed by the document and dashboard goals: the starting point is an
  // existing file or dataset, not a photo.
  Taxon(
    id: 'from_my_content',
    label: 'From my own file or data',
    icon: Icons.table_chart_outlined,
  ),
];

Taxon? _find(List<Taxon> list, String? id) {
  if (id == null) return null;
  for (final t in list) {
    if (t.id == id) return t;
  }
  return null;
}

Taxon? useCaseById(String? id) => _find(useCases, id);
Taxon? nicheById(String? id) => _find(niches, id);
Taxon? outputTypeById(String? id) => _find(outputTypes, id);
Taxon? inputMethodById(String? id) => _find(inputMethods, id);

/// Label lookups that degrade gracefully on an unknown id rather than
/// throwing, so stale data can never crash a list row.
String useCaseLabel(String? id) => useCaseById(id)?.label ?? '—';
String nicheLabel(String? id) => nicheById(id)?.label ?? '—';
String outputTypeLabel(String? id) => outputTypeById(id)?.label ?? '—';
String inputMethodLabel(String? id) => inputMethodById(id)?.label ?? '—';
