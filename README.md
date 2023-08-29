# changelog-template-action

Generate changelogs from templates with reference to git history, tags and merged pull requests

## Usage

* template file (release-note-with-body.md.j2)

```markdown
[Compare {{ from_revision }} with {{ to_revision }}]({{ env('GITHUB_SERVER_URL') }}/{{ owner }}/{{ repo }}/compare/{{ from_revision }}...{{ to_revision }})

## Changes

{% for pull_request in pull_requests %}
* [{{ pull_request. title }}]({{ pull_request.html_url }}) - {{ pull_request.user.login }} {{ pull_request.merged_at }}  
{%- if 'body' in pull_request -%}
  * <details><summary>details</summary>
    
    {{ pull_request.body | indent(4) }}
    </details>
{%- endif %}
{%- endfor %}
```

* workflow

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-tags: true
          fetch-depth: 0
      - name: changelog
        id: changelog
        uses: srz-zumix/changelog-template-action@main
        with:
          template_file: release-note-with-body.md.j2
          output_file: changelog.md
          from: "v1.1.0"
          to: "v1.2.0"
```
