@'
name: ci-master-pr

on:
  push:
    branches:
    - master
    tags:
    - '**'
  pull_request:
    branches:
    - master
  merge_group:
jobs:
  test-nogitdiff:
    runs-on: ubuntu-latest
    container:
      image: mcr.microsoft.com/powershell:lts-7.2-alpine-3.17
    steps:
    - run: |
        apk add --no-cache git
    - uses: actions/checkout@v3
    - name: Ignore git permissions
      run: |
        git config --global --add safe.directory "$( pwd )"
    - name: Generate variants
      run: |
        pwsh -Command '
        $ErrorActionPreference = "Stop"
        Install-Module -Name Generate-DockerImageVariants -Force -Scope CurrentUser -Verbose
        Generate-DockerImageVariants .
        '
    - name: Test - no git diff
      run: |
        git diff --exit-code
'@

# Group variants by the package version
$groups = $VARIANTS | Group-Object -Property { $_['_metadata']['job_group_key'] } | Sort-Object { [version]$_.Name.Split('-')[0] } -Descending
$WORKFLOW_JOB_NAMES = $groups | % { "build-$( $_.Name.Replace('.', '-') )" }
foreach ($g in $groups) {
@"


  build-$( $g.Name.Replace('.', '-') ):
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Display system info (linux)
      run: |
        set -e
        hostname
        whoami
        cat /etc/*release
        lscpu
        free
        df -h
        pwd
        docker info
        docker version

    # See: https://github.com/docker/build-push-action/blob/v2.6.1/docs/advanced/cache.md#github-cache
    - name: Set up QEMU
      uses: docker/setup-qemu-action@v2

    - name: Set up Docker Buildx
      id: buildx
      uses: docker/setup-buildx-action@v2

    - name: Cache Docker layers
      uses: actions/cache@v3
      with:
        path: /tmp/.buildx-cache
        key: `${{ runner.os }}-buildx-$( $g.Name )-`${{ github.sha }}
        restore-keys: |
          `${{ runner.os }}-buildx-$( $g.Name )-
          `${{ runner.os }}-buildx-

    - name: Login to Docker Hub registry
      # Run on master and tags
      if: github.ref == 'refs/heads/master' || startsWith(github.ref, 'refs/tags/')
      uses: docker/login-action@v2
      with:
        username: `${{ secrets.DOCKERHUB_REGISTRY_USER }}
        password: `${{ secrets.DOCKERHUB_REGISTRY_PASSWORD }}


"@

foreach ($v in $g.Group) {
@"
    # This step generates the docker tags
    - name: Prepare
      id: prep-$( $v['tag' ].Replace('.', '-') )
      run: |
        set -e

        # Get ref, i.e. <branch_name> from refs/heads/<branch_name>, or <tag-name> from refs/tags/<tag_name>. E.g. 'master' or 'v0.0.0'
        REF=`$( echo "`${GITHUB_REF}" | rev | cut -d '/' -f 1 | rev )

        # Get short commit hash E.g. 'abc0123'
        SHA=`$( echo "`${GITHUB_SHA}" | cut -c1-7 )

        # Generate docker image tags
        # E.g. 'v0.0.0-<variant>' and 'v0.0.0-abc0123-<variant>'
        # E.g. 'master-<variant>' and 'master-abc0123-<variant>'
        VARIANT="$( $v['tag'] )"
        REF_VARIANT="`${REF}-`${VARIANT}"
        REF_SHA_VARIANT="`${REF}-`${SHA}-`${VARIANT}"

        # Pass variables to next step
        echo "VARIANT_BUILD_DIR=`$VARIANT_BUILD_DIR" >> `$GITHUB_OUTPUT
        echo "VARIANT=`$VARIANT" >> `$GITHUB_OUTPUT
        echo "REF_VARIANT=`$REF_VARIANT" >> `$GITHUB_OUTPUT
        echo "REF_SHA_VARIANT=`$REF_SHA_VARIANT" >> `$GITHUB_OUTPUT

    - name: $( $v['tag' ] ) - Build (PRs)
      # Run only on pull requests
      if: github.event_name == 'pull_request'
      uses: docker/build-push-action@v3
      with:
        context: $( $v['build_dir_rel'] )
        platforms: $( $v['_metadata']['platforms'] -join ',' )
        push: false
        tags: |
          `${{ github.repository }}:`${{ steps.prep-$( $v['tag'].Replace('.', '-') ).outputs.REF_VARIANT }}
          `${{ github.repository }}:`${{ steps.prep-$( $v['tag'].Replace('.', '-') ).outputs.REF_SHA_VARIANT }}
        cache-from: type=local,src=/tmp/.buildx-cache
        cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max

    - name: $( $v['tag' ] ) - Build and push (master)
      # Run only on master
      if: github.ref == 'refs/heads/master'
      uses: docker/build-push-action@v3
      with:
        context: $( $v['build_dir_rel'] )
        platforms: $( $v['_metadata']['platforms'] -join ',' )
        push: true
        tags: |
          `${{ github.repository }}:`${{ steps.prep-$( $v['tag'].Replace('.', '-') ).outputs.REF_VARIANT }}
          `${{ github.repository }}:`${{ steps.prep-$( $v['tag'].Replace('.', '-') ).outputs.REF_SHA_VARIANT }}
        cache-from: type=local,src=/tmp/.buildx-cache
        cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max

    - name: $( $v['tag' ] ) - Build and push (release)
      if: startsWith(github.ref, 'refs/tags/')
      uses: docker/build-push-action@v3
      with:
        context: $( $v['build_dir_rel'] )
        platforms: $( $v['_metadata']['platforms'] -join ',' )
        push: true
        tags: |
          `${{ github.repository }}:`${{ steps.prep-$( $v['tag'].Replace('.', '-') ).outputs.VARIANT }}
          `${{ github.repository }}:`${{ steps.prep-$( $v['tag'].Replace('.', '-') ).outputs.REF_VARIANT }}
          `${{ github.repository }}:`${{ steps.prep-$( $v['tag'].Replace('.', '-') ).outputs.REF_SHA_VARIANT }}

"@

if ( $v['tag_as_latest'] ) {
@'
          ${{ github.repository }}:latest

'@
}
@'
        cache-from: type=local,src=/tmp/.buildx-cache
        cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max


'@
}
@'
    # Temp fix
    # https://github.com/docker/build-push-action/issues/252
    # https://github.com/moby/buildkit/issues/1896
    - name: Move cache
      run: |
        rm -rf /tmp/.buildx-cache
        mv /tmp/.buildx-cache-new /tmp/.buildx-cache
'@
}

@"


  update-draft-release:
    needs:
      - $( $WORKFLOW_JOB_NAMES -join "`n      - " )
    if: github.ref == 'refs/heads/master'
    runs-on: ubuntu-latest
    steps:
      # Drafts your next Release notes as Pull Requests are merged into "master"
      - uses: release-drafter/release-drafter@v5
        with:
          config-name: release-drafter.yml
          publish: false
        env:
          GITHUB_TOKEN: `${{ secrets.GITHUB_TOKEN }}

  publish-draft-release:
    needs:
      - $( $WORKFLOW_JOB_NAMES -join "`n      - " )
    if: startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    steps:
      # Drafts your next Release notes as Pull Requests are merged into "master"
      - uses: release-drafter/release-drafter@v5
        with:
          config-name: release-drafter.yml
          publish: true
          name: `${{ github.ref_name }} # E.g. 'master' or 'v1.2.3'
          tag: `${{ github.ref_name }} # E.g. 'master' or 'v1.2.3'
        env:
          GITHUB_TOKEN: `${{ secrets.GITHUB_TOKEN }}

  update-dockerhub-description:
    needs:
      - $( $WORKFLOW_JOB_NAMES -join "`n      - " )
    if: github.ref == 'refs/heads/master'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Docker Hub Description
      uses: peter-evans/dockerhub-description@v3
      with:
        username: `${{ secrets.DOCKERHUB_REGISTRY_USER }}
        password: `${{ secrets.DOCKERHUB_REGISTRY_PASSWORD }}
        repository: `${{ github.repository }}
        short-description: `${{ github.event.repository.description }}

"@
