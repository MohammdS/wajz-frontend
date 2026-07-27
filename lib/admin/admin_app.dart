import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import 'admin_api.dart';

const _navItems = [
  ('Overview', Icons.dashboard_outlined),
  ('Stories', Icons.auto_stories_outlined),
  ('Articles', Icons.article_outlined),
  ('News Studio', Icons.edit_note_outlined),
  ('Ingestion', Icons.sync_outlined),
  ('Sources', Icons.rss_feed_outlined),
  ('Users', Icons.people_outline),
  ('AI Runs', Icons.smart_toy_outlined),
  ('Audit Logs', Icons.history_outlined),
  ('Settings', Icons.settings_outlined),
];

class WajzAdminApp extends StatefulWidget {
  const WajzAdminApp({super.key, required this.authService});

  final AuthService authService;

  @override
  State<WajzAdminApp> createState() => _WajzAdminAppState();
}

class _WajzAdminAppState extends State<WajzAdminApp> {
  late final AdminApi api;
  late final Future<AdminSession?> restored;
  AdminSession? session;

  @override
  void initState() {
    super.initState();
    api = AdminApi(widget.authService);
    restored = api.restore();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wajz Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF237C79),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
        ),
      ),
      home: FutureBuilder<AdminSession?>(
        future: restored,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          session ??= snapshot.data;
          if (session == null) {
            return AdminLogin(
              api: api,
              onLogin: (value) => setState(() => session = value),
            );
          }
          return AdminShell(
            api: api,
            session: session!,
            onLogout: () async {
              await api.logout();
              setState(() => session = null);
            },
          );
        },
      ),
    );
  }
}

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key, required this.api, required this.onLogin});

  final AdminApi api;
  final ValueChanged<AdminSession> onLogin;

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final email = TextEditingController(text: 'admin@wajz.app');
  final name = TextEditingController(text: 'Wajz Admin');
  final password = TextEditingController();
  final bearerToken = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final token = bearerToken.text.trim();
      widget.onLogin(
        token.isNotEmpty
            ? await widget.api.loginWithToken(token)
            : widget.api.productionAuthEnabled
            ? await widget.api.loginWithPassword(
                email.text.trim(),
                password.text,
              )
            : await widget.api.login(
                email.text.trim(),
                displayName: name.text.trim(),
              ),
      );
    } catch (exception) {
      setState(() {
        error =
            exception is DioException && exception.response?.statusCode == 403
            ? 'This account does not have an admin role.'
            : 'Sign in failed. Check the backend and account.';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> googleSignIn() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.api.signInWithGoogle();
    } catch (_) {
      if (mounted) setState(() => error = 'Could not start Google sign-in.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    name.dispose();
    password.dispose();
    bearerToken.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 430,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'واجِز',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Admin Dashboard',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Admin email'),
                  ),
                  if (widget.api.productionAuthEnabled) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: loading ? null : (_) => submit(),
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ],
                  if (widget.api.developmentLoginEnabled) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: bearerToken,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Production bearer token (optional)',
                      helperText: 'Use a Supabase JWT when AUTH_MODE=supabase.',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    child: loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in securely'),
                  ),
                  if (widget.api.productionAuthEnabled) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: loading ? null : googleSignIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                    ),
                  ],
                  if (!widget.api.productionAuthEnabled &&
                      !widget.api.developmentLoginEnabled) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Supabase is not configured in this build. Paste an admin bearer token above.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Access is verified by the backend. A normal Wajz account cannot open admin APIs.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final AdminApi api;
  final AdminSession session;
  final VoidCallback onLogout;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int selected = 0;

  Widget page() => switch (selected) {
    0 => OverviewPage(api: widget.api),
    1 => StoriesPage(api: widget.api, session: widget.session),
    2 => ArticlesPage(api: widget.api, session: widget.session),
    3 => StudioPage(api: widget.api, session: widget.session),
    4 => IngestionPage(api: widget.api, session: widget.session),
    5 => SourcesPage(api: widget.api, session: widget.session),
    6 => UsersPage(api: widget.api, session: widget.session),
    7 => AiRunsPage(api: widget.api),
    8 => AuditLogsPage(api: widget.api),
    _ => SettingsPage(api: widget.api, session: widget.session),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 245,
            color: const Color(0xFF10272A),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 22, 24, 18),
                    child: Text(
                      'واجِز  ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (var index = 0; index < _navItems.length; index++)
                    _NavItem(
                      label: _navItems[index].$1,
                      icon: _navItems[index].$2,
                      selected: selected == index,
                      onTap: () => setState(() => selected = index),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.session.email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(widget.session.role),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: widget.onLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      Text(
                        _navItems[selected].$1,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      const Icon(Icons.shield_outlined),
                      const SizedBox(width: 8),
                      const Text('Backend-enforced access'),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: page(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.white.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.api});
  final AdminApi api;

  @override
  Widget build(BuildContext context) {
    return AdminFuture<Map<String, dynamic>>(
      load: () => api.getMap('/admin/overview'),
      builder: (data, refresh) {
        final metrics = [
          ('Stories today', data['stories_today'], Icons.auto_stories),
          ('Articles ingested', data['articles_today'], Icons.article),
          ('Pending review', data['pending_review_stories'], Icons.rate_review),
          ('Failed feeds', data['failed_feeds'], Icons.rss_feed),
          ('Failed articles', data['failed_articles'], Icons.error_outline),
          ('Active users', data['active_users'], Icons.people),
          ('AI failures', data['ai_failures'], Icons.smart_toy_outlined),
          (
            'Pending translations',
            data['pending_translations'],
            Icons.translate,
          ),
          ('Unhealthy sources', data['unhealthy_sources'], Icons.monitor_heart),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Operational overview',
              subtitle: 'Live health, review queues, ingestion, and AI status.',
              onRefresh: refresh,
            ),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in metrics)
                  MetricCard(
                    label: metric.$1,
                    value: '${metric.$2 ?? 0}',
                    icon: metric.$3,
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SectionCard(
              title: 'Latest ingestion status',
              child: data['latest_ingestion'] == null
                  ? const EmptyState('No ingestion runs yet.')
                  : JsonView(data['latest_ingestion']),
            ),
          ],
        );
      },
    );
  }
}

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key, required this.api, required this.session});
  final AdminApi api;
  final AdminSession session;

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  final search = TextEditingController();
  String status = '';
  int page = 1;
  int revision = 0;

  Future<Map<String, dynamic>> load() => widget.api.getMap(
    '/admin/stories',
    query: {
      'search': search.text.trim().isEmpty ? null : search.text.trim(),
      'status': status.isEmpty ? null : status,
      'page': page,
    },
  );

  Future<void> action(Map<String, dynamic> story, String value) async {
    if (value == 'edit') {
      await editStory(context, widget.api, story['id']);
      setState(() => revision++);
      return;
    }
    if (!await confirm(context, '$value this story?')) return;
    await widget.api.post('/admin/stories/${story['id']}/action', {
      'action': value,
    });
    setState(() => revision++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminFuture<Map<String, dynamic>>(
      key: ValueKey(revision),
      load: load,
      builder: (data, refresh) {
        final items = (data['items'] as List).cast<Map<String, dynamic>>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Story management',
              subtitle:
                  'Review and explicitly publish source-attributed stories.',
              onRefresh: refresh,
            ),
            FilterBar(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: search,
                    decoration: const InputDecoration(
                      labelText: 'Search stories',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => setState(() => revision++),
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All statuses')),
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      DropdownMenuItem(
                        value: 'pending_review',
                        child: Text('Pending review'),
                      ),
                      DropdownMenuItem(
                        value: 'published',
                        child: Text('Published'),
                      ),
                      DropdownMenuItem(
                        value: 'archived',
                        child: Text('Archived'),
                      ),
                      DropdownMenuItem(
                        value: 'rejected',
                        child: Text('Rejected'),
                      ),
                    ],
                    onChanged: (value) => setState(() => status = value ?? ''),
                  ),
                ),
              ],
            ),
            SectionCard(
              title: '${data['total']} stories',
              child: items.isEmpty
                  ? const EmptyState('No stories match these filters.')
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Headline')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Confidence')),
                          DataColumn(label: Text('Sources')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: [
                          for (final story in items)
                            DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 360,
                                    child: Text(
                                      story['headline'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  onTap: () => showStory(
                                    context,
                                    widget.api,
                                    story['id'],
                                  ),
                                ),
                                DataCell(
                                  StatusBadge(story['status'] ?? 'draft'),
                                ),
                                DataCell(Text(story['category'] ?? '—')),
                                DataCell(
                                  StatusBadge(
                                    story['confidence_label'] ?? 'unknown',
                                  ),
                                ),
                                DataCell(Text('${story['source_count'] ?? 0}')),
                                DataCell(
                                  widget.session.canEdit
                                      ? PopupMenuButton<String>(
                                          onSelected: (value) =>
                                              action(story, value),
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit story'),
                                            ),
                                            PopupMenuItem(
                                              value: 'publish',
                                              child: Text('Publish'),
                                            ),
                                            PopupMenuItem(
                                              value: 'submit_review',
                                              child: Text('Submit for review'),
                                            ),
                                            PopupMenuItem(
                                              value: 'save_draft',
                                              child: Text('Save as draft'),
                                            ),
                                            PopupMenuItem(
                                              value: 'rerun_synthesis',
                                              child: Text('Re-run synthesis'),
                                            ),
                                            PopupMenuItem(
                                              value: 'rerun_translation',
                                              child: Text('Re-run translation'),
                                            ),
                                            PopupMenuItem(
                                              value: 'archive',
                                              child: Text('Archive'),
                                            ),
                                            PopupMenuItem(
                                              value: 'reject',
                                              child: Text('Reject'),
                                            ),
                                          ],
                                        )
                                      : const Text('Read only'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
            PaginationBar(
              page: page,
              total: data['total'] as int,
              onPage: (value) => setState(() {
                page = value;
                revision++;
              }),
            ),
          ],
        );
      },
    );
  }
}

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key, required this.api, required this.session});
  final AdminApi api;
  final AdminSession session;

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  final search = TextEditingController();
  final selectedIds = <String>{};
  String status = '';
  int page = 1;
  int revision = 0;

  Future<void> reprocessSelected() async {
    if (selectedIds.isEmpty) return;
    if (!await confirm(
      context,
      'Reprocess ${selectedIds.length} selected articles?',
    )) {
      return;
    }
    await widget.api.post('/admin/articles/reprocess-selected', {
      'article_ids': selectedIds.toList(),
    });
    setState(() {
      selectedIds.clear();
      revision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminFuture<Map<String, dynamic>>(
      key: ValueKey(revision),
      load: () => widget.api.getMap(
        '/admin/articles',
        query: {
          'search': search.text.isEmpty ? null : search.text,
          'status': status.isEmpty ? null : status,
          'page': page,
        },
      ),
      builder: (data, refresh) {
        final items = (data['items'] as List).cast<Map<String, dynamic>>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Article management',
              subtitle:
                  'Inspect collected text, processing state, and clustering.',
              onRefresh: refresh,
              actions: widget.session.canEdit
                  ? [
                      FilledButton.icon(
                        onPressed: selectedIds.isEmpty
                            ? null
                            : reprocessSelected,
                        icon: const Icon(Icons.replay),
                        label: Text(
                          'Reprocess selected (${selectedIds.length})',
                        ),
                      ),
                    ]
                  : const [],
            ),
            FilterBar(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: search,
                    decoration: const InputDecoration(
                      labelText: 'Search URL or title',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => setState(() => revision++),
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All statuses'),
                      ),
                      for (final value in [
                        'collected',
                        'cleaned',
                        'processed',
                        'clustered',
                        'summarized',
                        'failed',
                        'ignored',
                      ])
                        DropdownMenuItem(value: value, child: Text(value)),
                    ],
                    onChanged: (value) => setState(() => status = value ?? ''),
                  ),
                ),
              ],
            ),
            SectionCard(
              title: '${data['total']} articles',
              child: items.isEmpty
                  ? const EmptyState('No articles match these filters.')
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Article')),
                          DataColumn(label: Text('Source')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Region')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: [
                          for (final article in items)
                            DataRow(
                              selected: selectedIds.contains(article['id']),
                              onSelectChanged: widget.session.canEdit
                                  ? (selected) => setState(() {
                                      final id = article['id'] as String;
                                      selected == true
                                          ? selectedIds.add(id)
                                          : selectedIds.remove(id);
                                    })
                                  : null,
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 360,
                                    child: Text(
                                      article['title'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  onTap: () => showArticle(
                                    context,
                                    widget.api,
                                    article['id'],
                                  ),
                                ),
                                DataCell(Text(article['source_name'] ?? '—')),
                                DataCell(
                                  StatusBadge(article['status'] ?? 'unknown'),
                                ),
                                DataCell(Text(article['category'] ?? '—')),
                                DataCell(Text(article['region'] ?? '—')),
                                DataCell(
                                  widget.session.canEdit
                                      ? PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            if (value == 'attach') {
                                              final storyId = await promptText(
                                                context,
                                                'Attach to story',
                                                'Story ID',
                                              );
                                              if (storyId == null) return;
                                              await widget.api.post(
                                                '/admin/articles/${article['id']}/action',
                                                {
                                                  'action': 'attach',
                                                  'story_id': storyId,
                                                },
                                              );
                                              setState(() => revision++);
                                              return;
                                            }
                                            await widget.api.post(
                                              '/admin/articles/${article['id']}/action',
                                              {'action': value},
                                            );
                                            setState(() => revision++);
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'reprocess',
                                              child: Text('Reprocess'),
                                            ),
                                            PopupMenuItem(
                                              value: 'create_story',
                                              child: Text('Create story'),
                                            ),
                                            PopupMenuItem(
                                              value: 'attach',
                                              child: Text('Attach to story'),
                                            ),
                                            PopupMenuItem(
                                              value: 'ignore',
                                              child: Text('Ignore'),
                                            ),
                                          ],
                                        )
                                      : const Text('Read only'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
            PaginationBar(
              page: page,
              total: data['total'] as int,
              onPage: (value) => setState(() {
                page = value;
                revision++;
              }),
            ),
          ],
        );
      },
    );
  }
}

class StudioPage extends StatefulWidget {
  const StudioPage({super.key, required this.api, required this.session});
  final AdminApi api;
  final AdminSession session;

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  final urls = TextEditingController();
  final title = TextEditingController();
  final summary = TextEditingController();
  final synthesis = TextEditingController();
  final facts = TextEditingController();
  final why = TextEditingController();
  bool loading = false;
  String result = '';
  late final Future<List<dynamic>> templates = widget.api.getList(
    '/admin/studio/templates',
  );

  Future<void> importUrls() async {
    final values = urls.text
        .split(RegExp(r'[\r\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (values.isEmpty || values.length > 10) {
      setState(() => result = 'Enter between 1 and 10 URLs.');
      return;
    }
    await run(
      () => widget.api.post('/admin/studio/from-urls', {
        'urls': values,
        'status': 'draft',
      }),
    );
  }

  Future<void> createManual() async {
    await run(
      () => widget.api.post('/admin/studio/manual', {
        'title': title.text,
        'summary': summary.text,
        'full_synthesis': synthesis.text,
        'key_facts': facts.text
            .split('\n')
            .where((item) => item.trim().isNotEmpty)
            .toList(),
        'why_it_matters': why.text,
        'language': 'en',
        'importance_score': 0.5,
        'confidence_label': 'single_source',
        'sources': <String>[],
        'related_urls': <String>[],
        'status': 'draft',
      }),
    );
  }

  Future<dynamic> run(Future<dynamic> Function() action) async {
    setState(() {
      loading = true;
      result = '';
    });
    try {
      final response = await action();
      setState(
        () => result = const JsonEncoder.withIndent('  ').convert(response),
      );
      return response;
    } catch (exception) {
      setState(
        () => result = exception is DioException
            ? errorText(exception)
            : exception.toString(),
      );
      return null;
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> runAiAction(String action) async {
    final sourceText = synthesis.text.trim().isNotEmpty
        ? synthesis.text.trim()
        : summary.text.trim();
    if (title.text.trim().isEmpty || sourceText.isEmpty) {
      setState(
        () => result =
            'Add a title and summary or full synthesis before using AI actions.',
      );
      return;
    }
    final response = await run(
      () => widget.api.post('/admin/studio/ai-action', {
        'action': action,
        'title': title.text.trim(),
        'text': sourceText,
        if (action == 'translate') 'target_language': 'ar',
      }),
    );
    if (response is! Map) return;
    final value = response['result'];
    setState(() {
      if (action == 'generate_summary' && value is String) {
        summary.text = value;
      } else if (action == 'generate_key_facts' && value is List) {
        facts.text = value.join('\n');
      } else if (action == 'generate_why_it_matters' && value is String) {
        why.text = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.canEdit) {
      return const EmptyState('Viewer accounts cannot create content.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'News Studio',
          subtitle:
              'AI output is editable and defaults to draft. Publishing is explicit.',
        ),
        FutureBuilder<List<dynamic>>(
          future: templates,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Could not load templates: ${readableError(snapshot.error)}',
              );
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final raw in snapshot.requireData)
                  ActionChip(
                    label: Text(raw['name'] as String),
                    avatar: const Icon(Icons.description_outlined, size: 18),
                    onPressed: () =>
                        setState(() => title.text = '${raw['name']}: '),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SectionCard(
                title: 'Add from URL or multiple URLs',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: urls,
                      minLines: 7,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        hintText:
                            'One public http/https article URL per line (2–10 for synthesis)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: loading ? null : importUrls,
                      icon: const Icon(Icons.security),
                      label: const Text('Fetch safely and create draft'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Localhost, private networks, metadata services, file://, and ftp:// are blocked.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SectionCard(
                title: 'Manual story',
                child: Column(
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: summary,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Summary'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: synthesis,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Full synthesis',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: facts,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Key facts, one per line',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: why,
                      decoration: const InputDecoration(
                        labelText: 'Why it matters',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'AI drafting tools',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final action in const [
                          ('generate_summary', 'Summary'),
                          ('generate_key_facts', 'Key facts'),
                          ('generate_why_it_matters', 'Why it matters'),
                          ('detect_uncertainty', 'Uncertainty'),
                          ('detect_opinion', 'Opinion'),
                          ('generate_source_comparison', 'Source comparison'),
                          ('generate_arabic', 'Arabic version'),
                        ])
                          ActionChip(
                            label: Text(action.$2),
                            avatar: const Icon(
                              Icons.auto_awesome_outlined,
                              size: 17,
                            ),
                            onPressed: loading
                                ? null
                                : () => runAiAction(action.$1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: loading ? null : createManual,
                      child: const Text('Save manual draft'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (loading) const LinearProgressIndicator(),
        if (result.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionCard(title: 'Studio result', child: SelectableText(result)),
        ],
      ],
    );
  }
}

class IngestionPage extends StatefulWidget {
  const IngestionPage({super.key, required this.api, required this.session});
  final AdminApi api;
  final AdminSession session;

  @override
  State<IngestionPage> createState() => _IngestionPageState();
}

class _IngestionPageState extends State<IngestionPage> {
  int revision = 0;
  bool actionLoading = false;

  Future<void> execute(
    String path, {
    Map<String, dynamic>? data,
    String? confirmation,
  }) async {
    if (confirmation != null && !await confirm(context, confirmation)) return;
    setState(() => actionLoading = true);
    try {
      final response = await widget.api.post(path, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response is Map && response['status'] != null
                ? 'Completed: ${response['status']}'
                : 'Operation completed.',
          ),
        ),
      );
      setState(() => revision++);
    } on DioException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorText(exception))));
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFuture<List<dynamic>>(
      key: ValueKey(revision),
      load: () => widget.api.getList('/admin/ingestion-runs'),
      builder: (runs, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Ingestion control',
            subtitle:
                'Run active feeds and inspect articles collected by each run.',
            onRefresh: refresh,
            actions: widget.session.canEdit
                ? [
                    FilledButton.icon(
                      onPressed: actionLoading
                          ? null
                          : () => execute('/admin/ingestion/run', data: {}),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run all active sources'),
                    ),
                    PopupMenuButton<String>(
                      enabled: !actionLoading,
                      tooltip: 'More ingestion actions',
                      onSelected: (action) {
                        switch (action) {
                          case 'retry_articles':
                            execute('/admin/ingestion/retry-failed');
                          case 'retry_feeds':
                            execute('/admin/ingestion/retry-failed-feeds');
                          case 'process':
                            execute('/admin/processing/run');
                          case 'translations':
                            execute('/admin/translations/run');
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'retry_articles',
                          child: Text('Retry failed articles'),
                        ),
                        PopupMenuItem(
                          value: 'retry_feeds',
                          child: Text('Retry failed feeds'),
                        ),
                        PopupMenuItem(
                          value: 'process',
                          child: Text('Process pending articles'),
                        ),
                        PopupMenuItem(
                          value: 'translations',
                          child: Text('Backfill missing translations'),
                        ),
                      ],
                      child: IgnorePointer(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.more_horiz),
                          label: const Text('More actions'),
                        ),
                      ),
                    ),
                  ]
                : const [],
          ),
          SectionCard(
            title: 'Ingestion runs',
            child: runs.isEmpty
                ? const EmptyState('No ingestion runs yet.')
                : Column(
                    children: [
                      for (final raw in runs)
                        ListTile(
                          leading: const Icon(Icons.sync),
                          title: Text('Run ${raw['id']}'),
                          subtitle: Text(
                            '${raw['articles_fetched']} articles • ${raw['sources_failed']} failed sources',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(raw['status']),
                              if (widget.session.canEdit &&
                                  {'queued', 'running'}.contains(raw['status']))
                                IconButton(
                                  tooltip: 'Cancel run',
                                  onPressed: actionLoading
                                      ? null
                                      : () => execute(
                                          '/admin/ingestion-runs/${raw['id']}/cancel',
                                          confirmation:
                                              'Cancel ingestion run ${raw['id']}?',
                                        ),
                                  icon: const Icon(Icons.cancel_outlined),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key, required this.api, required this.session});
  final AdminApi api;
  final AdminSession session;

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  int revision = 0;

  Future<void> addSource() async {
    final name = TextEditingController();
    final rss = TextEditingController();
    final website = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add RSS source'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rss,
                decoration: const InputDecoration(labelText: 'RSS URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: website,
                decoration: const InputDecoration(labelText: 'Website URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add source'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await widget.api.post('/admin/sources', {
      'name': name.text,
      'rss_url': rss.text,
      'website_url': website.text.isEmpty ? null : website.text,
      'language': 'en',
      'active': true,
      'reliability_level': 'unknown',
    });
    setState(() => revision++);
  }

  Future<void> editSource(Map<String, dynamic> source) async {
    final name = TextEditingController(text: source['name']);
    final rss = TextEditingController(text: source['rss_url']);
    final website = TextEditingController(text: source['website_url'] ?? '');
    final notes = TextEditingController(
      text: source['reliability_notes'] ?? '',
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit source'),
        content: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rss,
                decoration: const InputDecoration(labelText: 'RSS URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: website,
                decoration: const InputDecoration(labelText: 'Website URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                decoration: const InputDecoration(
                  labelText: 'Reliability notes',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await widget.api.put('/admin/sources/${source['id']}', {
      'name': name.text,
      'rss_url': rss.text,
      'website_url': website.text.isEmpty ? null : website.text,
      'reliability_notes': notes.text,
    });
    setState(() => revision++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminFuture<List<dynamic>>(
      key: ValueKey(revision),
      load: () => widget.api.getList('/admin/sources'),
      builder: (sources, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Source management',
            subtitle:
                'RSS configuration, source health, reliability, and manual runs.',
            onRefresh: refresh,
            actions: widget.session.canEdit
                ? [
                    FilledButton.icon(
                      onPressed: addSource,
                      icon: const Icon(Icons.add),
                      label: const Text('Add source'),
                    ),
                  ]
                : const [],
          ),
          SectionCard(
            title: '${sources.length} sources',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Source')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Language')),
                  DataColumn(label: Text('Health')),
                  DataColumn(label: Text('Failures')),
                  DataColumn(label: Text('Last success')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: [
                  for (final source in sources)
                    DataRow(
                      cells: [
                        DataCell(Text(source['name'])),
                        DataCell(Text(source['source_type'] ?? 'rss')),
                        DataCell(Text(source['language'] ?? '—')),
                        DataCell(
                          StatusBadge(
                            source['healthy'] == true ? 'healthy' : 'unhealthy',
                          ),
                        ),
                        DataCell(Text('${source['failure_count'] ?? 0}')),
                        DataCell(
                          Text(shortDate(source['last_successful_fetch'])),
                        ),
                        DataCell(
                          widget.session.canEdit
                              ? Wrap(
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit source',
                                      onPressed: () => editSource(source),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Test feed',
                                      onPressed: () async {
                                        await widget.api.post(
                                          '/admin/sources/${source['id']}/test',
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.health_and_safety_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Run now',
                                      onPressed: () async {
                                        await widget.api.post(
                                          '/admin/sources/${source['id']}/run',
                                        );
                                        setState(() => revision++);
                                      },
                                      icon: const Icon(Icons.play_arrow),
                                    ),
                                    Switch(
                                      value: source['active'] == true,
                                      onChanged: (value) async {
                                        await widget.api.put(
                                          '/admin/sources/${source['id']}',
                                          {'active': value},
                                        );
                                        setState(() => revision++);
                                      },
                                    ),
                                  ],
                                )
                              : const Text('Read only'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.api, required this.session});
  final AdminApi api;
  final AdminSession session;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final search = TextEditingController();
  int page = 1;
  int revision = 0;

  @override
  Widget build(BuildContext context) {
    return AdminFuture<Map<String, dynamic>>(
      key: ValueKey(revision),
      load: () => widget.api.getMap(
        '/admin/users',
        query: {
          'search': search.text.isEmpty ? null : search.text,
          'page': page,
        },
      ),
      builder: (data, refresh) {
        final users = (data['items'] as List).cast<Map<String, dynamic>>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'User management',
              subtitle:
                  'Profiles and preferences. Role changes require super_admin.',
              onRefresh: refresh,
            ),
            FilterBar(
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: search,
                    decoration: const InputDecoration(
                      labelText: 'Search users',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => setState(() => revision++),
                  ),
                ),
              ],
            ),
            SectionCard(
              title: '${data['total']} users',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Language')),
                    DataColumn(label: Text('Preferences')),
                    DataColumn(label: Text('Saved')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Admin role')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final user in users)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 250,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['display_name'] ?? 'Unnamed'),
                                  Text(
                                    user['email'],
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(user['preferred_language'] ?? 'en')),
                          DataCell(
                            Text(
                              '${user['preferences']?['topics']?.length ?? 0} topics / '
                              '${user['preferences']?['regions']?.length ?? 0} regions',
                            ),
                          ),
                          DataCell(Text('${user['saved_stories_count']}')),
                          DataCell(StatusBadge(user['account_status'])),
                          DataCell(
                            widget.session.isSuperAdmin
                                ? DropdownButton<String?>(
                                    value: user['admin_role'] as String?,
                                    hint: const Text('No role'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text('No role'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'viewer',
                                        child: Text('viewer'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'editor',
                                        child: Text('editor'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'super_admin',
                                        child: Text('super_admin'),
                                      ),
                                    ],
                                    onChanged: (value) async {
                                      await widget.api.patch(
                                        '/admin/users/${user['id']}',
                                        {'admin_role': value},
                                      );
                                      setState(() => revision++);
                                    },
                                  )
                                : Text(user['admin_role'] ?? '—'),
                          ),
                          DataCell(
                            widget.session.isSuperAdmin &&
                                    user['id'] != widget.session.id
                                ? TextButton(
                                    onPressed: () async {
                                      final disabling =
                                          user['account_status'] == 'active';
                                      if (!await confirm(
                                        context,
                                        '${disabling ? 'Disable' : 'Enable'} ${user['email']}?',
                                      )) {
                                        return;
                                      }
                                      await widget.api
                                          .patch('/admin/users/${user['id']}', {
                                            'account_status': disabling
                                                ? 'disabled'
                                                : 'active',
                                          });
                                      setState(() => revision++);
                                    },
                                    child: Text(
                                      user['account_status'] == 'active'
                                          ? 'Disable'
                                          : 'Enable',
                                    ),
                                  )
                                : const Text('—'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            PaginationBar(
              page: page,
              total: data['total'] as int,
              onPage: (value) => setState(() {
                page = value;
                revision++;
              }),
            ),
          ],
        );
      },
    );
  }
}

class AiRunsPage extends StatelessWidget {
  const AiRunsPage({super.key, required this.api});
  final AdminApi api;

  @override
  Widget build(BuildContext context) {
    return AdminFuture<List<dynamic>>(
      load: () => api.getList('/admin/ai-runs'),
      builder: (runs, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'AI run logs',
            subtitle:
                'Summarization, synthesis, translation, uncertainty, and failures.',
            onRefresh: refresh,
          ),
          SectionCard(
            title: '${runs.length} recent runs',
            child: runs.isEmpty
                ? const EmptyState('No AI runs recorded.')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Task')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Model')),
                        DataColumn(label: Text('Reference')),
                        DataColumn(label: Text('Started')),
                        DataColumn(label: Text('Error')),
                      ],
                      rows: [
                        for (final run in runs)
                          DataRow(
                            cells: [
                              DataCell(Text(run['task_type'])),
                              DataCell(StatusBadge(run['status'])),
                              DataCell(Text(run['model_name'] ?? '—')),
                              DataCell(
                                Text(
                                  '${run['input_reference_type'] ?? ''} '
                                  '${run['input_reference_id'] ?? ''}',
                                ),
                              ),
                              DataCell(Text(shortDate(run['created_at']))),
                              DataCell(
                                SizedBox(
                                  width: 280,
                                  child: Text(
                                    run['error_message'] ?? '—',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key, required this.api});
  final AdminApi api;

  @override
  Widget build(BuildContext context) {
    return AdminFuture<List<dynamic>>(
      load: () => api.getList('/admin/audit-logs', query: {'limit': 250}),
      builder: (logs, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Audit logs',
            subtitle:
                'Trace protected admin actions, actors, roles, and affected records.',
            onRefresh: refresh,
          ),
          SectionCard(
            title: '${logs.length} recent actions',
            child: logs.isEmpty
                ? const EmptyState('No admin actions recorded.')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Actor')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Action')),
                        DataColumn(label: Text('Target')),
                        DataColumn(label: Text('Details')),
                      ],
                      rows: [
                        for (final log in logs)
                          DataRow(
                            cells: [
                              DataCell(Text(shortDate(log['created_at']))),
                              DataCell(Text(log['actor_email'] ?? '—')),
                              DataCell(
                                StatusBadge(log['actor_role'] ?? 'unknown'),
                              ),
                              DataCell(Text(log['action'] ?? '—')),
                              DataCell(
                                Text(
                                  '${log['target_type'] ?? ''} ${log['target_id'] ?? ''}',
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip: 'View audit details',
                                  icon: const Icon(Icons.data_object),
                                  onPressed: () => showDialog<void>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        log['action'] ?? 'Audit details',
                                      ),
                                      content: SizedBox(
                                        width: 650,
                                        child: SingleChildScrollView(
                                          child: JsonView(log),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.api, required this.session});
  final AdminApi api;
  final AdminSession session;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final autoPublish = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    if (!widget.session.isSuperAdmin) {
      return const EmptyState('Settings require the super_admin role.');
    }
    return AdminFuture<List<dynamic>>(
      load: () => widget.api.getList('/admin/settings'),
      builder: (settings, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Settings',
            subtitle:
                'Protected operational configuration and publishing policy.',
            onRefresh: refresh,
          ),
          SectionCard(
            title: 'Publishing safeguards',
            child: ValueListenableBuilder<bool>(
              valueListenable: autoPublish,
              builder: (context, value, _) => SwitchListTile(
                title: const Text('Auto-publish AI-generated stories'),
                subtitle: const Text(
                  'Disabled by default. AI content should enter draft or pending review.',
                ),
                value: value,
                onChanged: (enabled) async {
                  await widget.api.put('/admin/settings/auto_publish', {
                    'value': {'enabled': enabled},
                    'description':
                        'Allow automatic publishing from the AI pipeline.',
                  });
                  autoPublish.value = enabled;
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Stored settings',
            child: settings.isEmpty
                ? const EmptyState('No custom settings stored.')
                : JsonView(settings),
          ),
        ],
      ),
    );
  }
}

class AdminFuture<T> extends StatefulWidget {
  const AdminFuture({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(T data, VoidCallback refresh) builder;

  @override
  State<AdminFuture<T>> createState() => _AdminFutureState<T>();
}

class _AdminFutureState<T> extends State<AdminFuture<T>> {
  late Future<T> future;

  @override
  void initState() {
    super.initState();
    future = widget.load();
  }

  void refresh() => setState(() => future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 400,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: readableError(snapshot.error),
            retry: refresh,
          );
        }
        return widget.builder(snapshot.requireData, refresh);
      },
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 5),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(left: 10),
              child: action,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 235,
      height: 125,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(spacing: 12, runSpacing: 12, children: children),
    );
  }
}

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.total,
    required this.onPage,
  });

  final int page;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    const pageSize = 25;
    final pages = (total / pageSize).ceil().clamp(1, 999999);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Page $page of $pages'),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Previous page',
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: page < pages ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.value, {super.key});
  final String value;

  @override
  Widget build(BuildContext context) {
    final normalized = value.toLowerCase();
    final color = switch (normalized) {
      'published' ||
      'succeeded' ||
      'success' ||
      'healthy' ||
      'active' => Colors.green,
      'failed' ||
      'error' ||
      'rejected' ||
      'unhealthy' ||
      'disabled' => Colors.red,
      'pending_review' ||
      'running' ||
      'partial' ||
      'developing' => Colors.orange,
      'super_admin' => Colors.deepPurple,
      'editor' => Colors.blue,
      _ => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value.replaceAll('_', ' '),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(message)),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42, color: Colors.red),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class JsonView extends StatelessWidget {
  const JsonView(this.value, {super.key});
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return SelectableText(const JsonEncoder.withIndent('  ').convert(value));
  }
}

Future<void> showStory(BuildContext context, AdminApi api, String id) async {
  final story = await api.getMap('/admin/stories/$id');
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(story['headline']),
      content: SizedBox(
        width: 850,
        height: 620,
        child: SingleChildScrollView(child: JsonView(story)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> editStory(BuildContext context, AdminApi api, String id) async {
  final story = await api.getMap('/admin/stories/$id');
  if (!context.mounted) return;
  final headline = TextEditingController(text: story['headline'] ?? '');
  final summary = TextEditingController(text: story['summary'] ?? '');
  final synthesis = TextEditingController(text: story['what_happened'] ?? '');
  final why = TextEditingController(text: story['why_it_matters'] ?? '');
  final notes = TextEditingController(text: story['editor_notes'] ?? '');
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit story'),
      content: SizedBox(
        width: 760,
        height: 620,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: headline,
                decoration: const InputDecoration(labelText: 'Headline'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: summary,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Summary'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: synthesis,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Full synthesis'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: why,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Why it matters'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Editor notes'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Save edits'),
        ),
      ],
    ),
  );
  if (accepted != true) return;
  await api.put('/admin/stories/$id', {
    'headline': headline.text,
    'summary': summary.text,
    'what_happened': synthesis.text,
    'why_it_matters': why.text,
    'editor_notes': notes.text,
  });
}

Future<void> showArticle(BuildContext context, AdminApi api, String id) async {
  final article = await api.getMap('/admin/articles/$id');
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(article['title']),
      content: SizedBox(
        width: 850,
        height: 620,
        child: SingleChildScrollView(child: JsonView(article)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<String?> promptText(
  BuildContext context,
  String title,
  String label,
) async {
  final controller = TextEditingController();
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (accepted != true || controller.text.trim().isEmpty) return null;
  return controller.text.trim();
}

Future<bool> confirm(BuildContext context, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm action'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
}

String shortDate(dynamic value) {
  if (value == null) return '—';
  final text = value.toString();
  return text.length > 16 ? text.substring(0, 16).replaceFirst('T', ' ') : text;
}

String readableError(Object? error) {
  if (error is DioException) return errorText(error);
  return error?.toString() ?? 'Unknown error';
}

String errorText(DioException exception) {
  final data = exception.response?.data;
  if (data is Map && data['detail'] != null) return data['detail'].toString();
  return 'Request failed (${exception.response?.statusCode ?? 'network error'}).';
}
