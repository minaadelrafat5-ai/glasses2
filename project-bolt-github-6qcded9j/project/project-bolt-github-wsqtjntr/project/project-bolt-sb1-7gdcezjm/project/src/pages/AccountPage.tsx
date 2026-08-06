import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Package, Heart, LogOut, User, Mail, Save } from 'lucide-react';
import { Button, Input, Spinner, Badge } from '@/components/ui';
import { useAuth } from '@/context';
import { fetchUserOrders, orderStatusToLabel } from '@/services/orderService';
import { formatMoney } from '@/lib/utils';
import type { Order } from '@/types';

export function AccountPage() {
  const { profile, signOut, updateProfile } = useAuth();
  const navigate = useNavigate();

  const [orders, setOrders] = useState<Order[]>([]);
  const [loadingOrders, setLoadingOrders] = useState(true);
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (profile) {
      setFirstName(profile.firstName ?? '');
      setLastName(profile.lastName ?? '');
    }
  }, [profile]);

  useEffect(() => {
    if (!profile) return;
    let active = true;
    setLoadingOrders(true);
    fetchUserOrders(profile.id)
      .then((o) => { if (active) setOrders(o); })
      .catch(() => { if (active) setOrders([]); })
      .finally(() => { if (active) setLoadingOrders(false); });
    return () => { active = false; };
  }, [profile]);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setSaved(false);
    try {
      await updateProfile({ firstName, lastName });
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {
      // surface error silently for now
    } finally {
      setSaving(false);
    }
  };

  const handleSignOut = async () => {
    await signOut();
    navigate('/');
  };

  if (!profile) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Spinner size={32} />
      </div>
    );
  }

  return (
    <div className="animate-fade-in">
      <div className="border-b border-ink-200 bg-white">
        <div className="container-app py-10">
          <h1 className="text-3xl font-semibold tracking-tight">Your account</h1>
          <p className="mt-1 text-ink-500">Manage your profile and view your orders.</p>
        </div>
      </div>

      <div className="container-app py-8">
        <div className="grid gap-8 md:grid-cols-3">
          {/* Profile */}
          <div className="md:col-span-1">
            <div className="rounded-2xl border border-ink-200 bg-white p-6">
              <div className="mb-4 flex items-center gap-3">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary-100 text-primary-700">
                  <User size={24} />
                </div>
                <div>
                  <p className="font-semibold text-ink-900">
                    {profile.firstName} {profile.lastName}
                  </p>
                  <p className="text-sm text-ink-500">{profile.email}</p>
                </div>
              </div>

              <Badge variant="neutral" className="mb-4 capitalize">{profile.role}</Badge>

              <form onSubmit={handleSave} className="space-y-4">
                <Input
                  label="First name"
                  name="firstName"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  placeholder="Jane"
                />
                <Input
                  label="Last name"
                  name="lastName"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  placeholder="Doe"
                />
                <Button type="submit" size="sm" isLoading={saving} disabled={saving}>
                  <Save size={16} />
                  {saved ? 'Saved!' : 'Save changes'}
                </Button>
              </form>

              <div className="mt-6 border-t border-ink-200 pt-4">
                <button
                  onClick={handleSignOut}
                  className="flex items-center gap-2 text-sm font-medium text-error-600 hover:text-error-700"
                >
                  <LogOut size={16} />
                  Sign out
                </button>
              </div>
            </div>
          </div>

          {/* Orders */}
          <div className="md:col-span-2">
            <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold">
              <Package size={20} />
              Order history
            </h2>

            {loadingOrders ? (
              <div className="flex justify-center py-12">
                <Spinner size={24} />
              </div>
            ) : orders.length > 0 ? (
              <div className="space-y-4">
                {orders.map((order) => (
                  <div key={order.id} className="rounded-2xl border border-ink-200 bg-white p-5">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-ink-900">Order #{order.id.slice(0, 8)}</p>
                        <p className="text-sm text-ink-500">
                          {new Date(order.createdAt).toLocaleDateString('en-US', {
                            year: 'numeric', month: 'short', day: 'numeric',
                          })}
                        </p>
                      </div>
                      <Badge variant="neutral" className="capitalize">
                        {orderStatusToLabel(order.status)}
                      </Badge>
                    </div>
                    <div className="mt-4 space-y-2">
                      {order.items.map((item) => (
                        <div key={item.id} className="flex items-center justify-between text-sm">
                          <span className="text-ink-700">
                            {item.productName} × {item.quantity}
                          </span>
                          <span className="text-ink-600">
                            {formatMoney(item.unitPriceCents * item.quantity)}
                          </span>
                        </div>
                      ))}
                    </div>
                    <div className="mt-4 flex items-center justify-between border-t border-ink-100 pt-3">
                      <span className="text-sm font-medium text-ink-600">Total</span>
                      <span className="font-semibold text-ink-900">{formatMoney(order.totalCents)}</span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-ink-300 py-16 text-center">
                <Package size={32} className="text-ink-300" />
                <p className="mt-3 text-sm font-medium text-ink-700">No orders yet</p>
                <p className="mt-1 text-sm text-ink-500">When you place your first order, it'll show up here.</p>
                <Link to="/shop" className="mt-4">
                  <Button size="sm">Browse frames</Button>
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
