## Description

<!-- Describe your changes in detail -->

## Type of Change

- [ ] New feature (new swimlane, user, role, etc.)
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Configuration change (warehouse size, auto-suspend, etc.)

## Terraform Changes

### Resources Added
<!-- List new resources being created -->
- [ ] Database(s):
- [ ] Warehouse(s):
- [ ] Role(s):
- [ ] User(s):
- [ ] Grant(s):

### Resources Modified
<!-- List existing resources being modified -->

### Resources Destroyed
<!-- List resources being removed (if any) -->

## Testing Checklist

- [ ] `terraform fmt` passed
- [ ] `terraform validate` passed
- [ ] `terraform plan` reviewed (check automated comment)
- [ ] Verified no unexpected resource deletions
- [ ] Tested in dev/non-production environment (if applicable)

## Impact Assessment

### Cost Impact
- [ ] No cost change
- [ ] Minor cost increase (estimate: $__/month)
- [ ] Major cost increase (estimate: $__/month)
- [ ] Cost decrease

### Security Impact
- [ ] No security impact
- [ ] New permissions granted (documented above)
- [ ] Permissions reduced
- [ ] New users/roles created

### Breaking Changes
- [ ] No breaking changes
- [ ] Breaking changes (documented in description)

## Documentation

- [ ] Updated README.md (if needed)
- [ ] Updated ARCHITECTURE.md (if needed)
- [ ] Updated module README (if module changed)
- [ ] Added inline comments for complex logic

## Rollback Plan

<!-- Describe how to rollback these changes if needed -->

## Additional Notes

<!-- Any additional information that reviewers should know -->

---

**Before submitting:**
1. Review the automated Terraform plan in the PR comments
2. Ensure all checkboxes above are addressed
3. Tag relevant reviewers
4. Link any related issues

