// Temporary probe to verify react-doctor's PR diff gate matches files under
// the literal `[locale]` route segment. The <button> below intentionally omits
// an explicit `type`, which react-doctor flags as a warning. Removed before merge.
export function ReactDoctorProbe() {
  return <button onClick={() => {}}>probe</button>;
}
