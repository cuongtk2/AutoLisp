using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

[assembly: CommandClass(typeof(AjsAutocad.MoveAttToOutPoly))]
namespace AjsAutocad
{
    public class MoveAttToOutPoly
    {
        [CommandMethod("MoveAttToOutPoly")]
        public void MoveAttToOutPolyCmd()
        {
            var doc = AcadApp.DocumentManager.MdiActiveDocument;
            var db  = doc.Database;
            var ed  = doc.Editor;
            try
            {
                // 1. Chọn polyline khép kín
                var peo = new PromptEntityOptions("\nChọn polyline ranh khép kín: ");
                peo.SetRejectMessage("\nPhải chọn Polyline!");
                peo.AddAllowedClass(typeof(Polyline), true);
                var per = ed.GetEntity(peo);
                if (per.Status != PromptStatus.OK) return;

                // 2. Chọn các block mốc góc ranh
                var pso = new PromptSelectionOptions
                {
                    MessageForAdding = "\nChọn các block mốc góc ranh: "
                };
                var ssf = new SelectionFilter(new[]
                {
                    new TypedValue((int)DxfCode.Start, "INSERT")
                });
                var psr = ed.GetSelection(pso, ssf);
                if (psr.Status != PromptStatus.OK) return;

                using (doc.LockDocument())
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    var poly = (Polyline)tr.GetObject(per.ObjectId, OpenMode.ForRead);
                    if (!poly.Closed)
                    {
                        ed.WriteMessage("\nPolyline phải khép kín!");
                        return;
                    }

                    foreach (SelectedObject so in psr.Value)
                    {
                        var br = tr.GetObject(so.ObjectId, OpenMode.ForRead) as BlockReference;
                        if (br == null || br.AttributeCollection.Count == 0) continue;

                        var pos2d = new Point2d(br.Position.X, br.Position.Y);

                        int vtxIdx = FindMatchingVertex(poly, pos2d, 1e-3);
                        if (vtxIdx < 0)
                        {
                            ed.WriteMessage($"\nBlock '{br.Name}' không nằm trên vertex nào, bỏ qua.");
                            continue;
                        }

                        Vector2d outDir = GetOutwardBisector(poly, vtxIdx);

                        foreach (ObjectId attId in br.AttributeCollection)
                        {
                            var att = (AttributeReference)tr.GetObject(attId, OpenMode.ForWrite);

                            double offset = att.Height * 2.0;
                            var newPos = new Point3d(
                                br.Position.X + outDir.X * offset,
                                br.Position.Y + outDir.Y * offset,
                                br.Position.Z);

                            // Đổi sang Middle Center
                            att.Justify         = AttachmentPoint.MiddleCenter;
                            att.AlignmentPoint  = newPos;
                        }
                    }

                    tr.Commit();
                    ed.WriteMessage("\nHoàn thành.");
                }
            }
            catch (System.Exception ex)
            {
                ed.WriteMessage($"\nLỗi: {ex.Message}");
            }
        }

        private int FindMatchingVertex(Polyline poly, Point2d pt, double tolerance)
        {
            int n = (int)poly.NumberOfVertices;
            for (int i = 0; i < n; i++)
            {
                if (poly.GetPoint2dAt(i).GetDistanceTo(pt) <= tolerance)
                    return i;
            }
            return -1;
        }

        private Vector2d GetOutwardBisector(Polyline poly, int vtxIdx)
        {
            int n  = (int)poly.NumberOfVertices;
            var v  = poly.GetPoint2dAt(vtxIdx);
            var vp = poly.GetPoint2dAt((vtxIdx - 1 + n) % n);
            var vn = poly.GetPoint2dAt((vtxIdx + 1) % n);

            var u1 = (vp - v).GetNormal();
            var u2 = (vn - v).GetNormal();

            var bisector = u1 + u2;

            if (bisector.Length < 1e-9)
            {
                var seg = (vn - vp).GetNormal();
                bisector = new Vector2d(-seg.Y, seg.X);
            }

            bisector = bisector.GetNormal();

            var testPt = new Point2d(v.X + bisector.X * 0.01, v.Y + bisector.Y * 0.01);
            if (IsInsidePoly(poly, testPt))
                bisector = bisector.Negate();

            return bisector;
        }

        private bool IsInsidePoly(Polyline poly, Point2d pt)
        {
            int n      = (int)poly.NumberOfVertices;
            bool inside = false;
            for (int i = 0, j = n - 1; i < n; j = i++)
            {
                var pi = poly.GetPoint2dAt(i);
                var pj = poly.GetPoint2dAt(j);
                if (((pi.Y > pt.Y) != (pj.Y > pt.Y)) &&
                    pt.X < (pj.X - pi.X) * (pt.Y - pi.Y) / (pj.Y - pi.Y) + pi.X)
                    inside = !inside;
            }
            return inside;
        }
    }
}
