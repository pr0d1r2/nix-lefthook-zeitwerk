#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

    export PATH="$BATS_TEST_DIRNAME/stubs:$PATH"
    export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"

    WORK="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$WORK"
    unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE 2>/dev/null || true
    git -C "$WORK" init -q
    git -C "$WORK" config user.email "test@test"
    git -C "$WORK" config user.name "Test"
}

run_cmd() {
    local cmd
    cmd=$(awk '/^pre-commit:/,/run:/' "$REPO_ROOT/lefthook-remote.yml" \
        | grep 'run:' | head -1 | sed 's/.*run: //')
    echo "$cmd"
}

@test "pre-commit run command calls bundle exec rake" {
    cmd=$(run_cmd)
    echo "$cmd" | grep -q "bundle exec rake"
}

@test "pre-commit has timeout" {
    timeout=$(awk '/^pre-commit:/,/timeout:/' "$REPO_ROOT/lefthook-remote.yml" \
        | grep 'timeout:' | head -1 | sed 's/.*timeout: //')
    [ -n "$timeout" ]
}

@test "pre-commit propagates failure" {
    export STUB_EXIT=1
    echo "class Foo; end" > "$WORK/app.rb"

    cmd=$(run_cmd)
    cmd="${cmd//\{staged_files\}/app.rb}"

    run bash -c "cd '$WORK' && $cmd"
    assert_failure
}

