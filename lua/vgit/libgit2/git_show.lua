local ffi = require('ffi')
local libgit2 = require('vgit.libgit2')
local git_show = require('vgit.git.git_show')

local git_show_lines = git_show.lines

function git_show.lines(reponame, filename, commit_hash)
  if not libgit2.is_enabled() then return git_show_lines(reponame, filename, commit_hash) end

  if not reponame then return nil, { 'reponame is required' } end

  local object_ptr
  local commit_ptr
  local commit_tree_ptr
  local entry_ptr
  local blob_ptr
  local content
  local oid
  local data
  local len
  local index_ptr
  local index_entry

  local repo_ptr = ffi.new('git_repository*[1]')
  local ret = libgit2.cli.git_repository_open(repo_ptr, reponame)
  if ret ~= 0 then return nil, libgit2.error() end

  -- find in index at first
  if commit_hash == nil then
    index_ptr = ffi.new('git_index*[1]')
    ret = libgit2.cli.git_repository_index(index_ptr, repo_ptr[0])
    if ret ~= 0 then goto OUT end
    index_entry = libgit2.cli.git_index_get_bypath(index_ptr[0], filename, 0)
  end

  if index_entry then
    oid = index_entry.id
  else
    object_ptr = ffi.new('git_object*[1]')
    ret = libgit2.cli.git_revparse_single(object_ptr, repo_ptr[0], commit_hash or 'HEAD')
    if ret ~= 0 then goto OUT end

    commit_ptr = ffi.new('git_commit*[1]')
    oid = libgit2.cli.git_object_id(object_ptr[0])
    ret = libgit2.cli.git_commit_lookup(commit_ptr, repo_ptr[0], oid)
    if ret ~= 0 then goto OUT end

    commit_tree_ptr = ffi.new('git_tree*[1]')
    ret = libgit2.cli.git_commit_tree(commit_tree_ptr, commit_ptr[0])
    if ret ~= 0 then goto OUT end

    entry_ptr = ffi.new('git_tree_entry*[1]')
    ret = libgit2.cli.git_tree_entry_bypath(entry_ptr, commit_tree_ptr[0], filename)
    if ret ~= 0 then goto OUT end
    if libgit2.cli.git_tree_entry_type(entry_ptr[0]) ~= libgit2.cli.GIT_OBJECT_BLOB then goto OUT end
    oid = libgit2.cli.git_tree_entry_id(entry_ptr[0])
  end

  blob_ptr = ffi.new('git_blob*[1]')
  ret = libgit2.cli.git_blob_lookup(blob_ptr, repo_ptr[0], oid)
  if ret ~= 0 then goto OUT end

  data = libgit2.cli.git_blob_rawcontent(blob_ptr[0])
  len = libgit2.cli.git_blob_rawsize(blob_ptr[0])
  -- 10 = 0xa = "\n"
  if len > 1 and data[len - 1] == 10 then
    len = len - 1
  end
  content = ffi.string(data, len)

  ::OUT::
  if index_ptr and index_ptr[0] then libgit2.cli.git_index_free(index_ptr[0]) end
  if blob_ptr and blob_ptr[0] then libgit2.cli.git_blob_free(blob_ptr[0]) end
  if entry_ptr and entry_ptr[0] then libgit2.cli.git_tree_entry_free(entry_ptr[0]) end
  if commit_tree_ptr and commit_tree_ptr[0] ~= nil then libgit2.cli.git_tree_free(commit_tree_ptr[0]) end
  if commit_ptr and commit_ptr[0] then libgit2.cli.git_commit_free(commit_ptr[0]) end
  if object_ptr and object_ptr[0] then libgit2.cli.git_object_free(object_ptr[0]) end
  libgit2.cli.git_repository_free(repo_ptr[0])

  if ret ~= 0 then return libgit2.error() end
  return vim.split(content, '\n')
end

return git_show
